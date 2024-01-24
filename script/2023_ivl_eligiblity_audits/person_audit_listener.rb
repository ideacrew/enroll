require 'tempfile'

AUDIT_START_DATE = Date.new(2022,10,1)
AUDIT_END_DATE = Date.new(2023,10,1)
PASSIVE_RENEWAL_DATE = Time.mktime(2022,11,1,0,0,0)

class PersonAuditListener
  include AmqpClientHelpers

  def initialize(chan, q)
    @channel = chan
    @connection = chan.connection
    @queue = q
  end

  def self.queue_name
    config = Rails.application.config.acapi
    "#{config.hbx_id}.#{config.environment_name}.q.#{config.app_id}.dc_ivl_audit_people"
  end

  def self.result_queue_name
    config = Rails.application.config.acapi
    "#{config.hbx_id}.#{config.environment_name}.q.#{config.app_id}.dc_ivl_audit_results"
  end

  def self.create_queue(ch)
    ch.queue(queue_name, :durable => true)
  end

  def self.run
    conn = Bunny.new(Rails.application.config.acapi.remote_broker_uri, :heartbeat => 15)
    conn.start
    chan = conn.create_channel
    chan.prefetch(1)
    q = create_queue(chan)
    self.new(chan, q).subscribe
  end

  def subscribe
    @benefit_packages = IvlEligibilityAudits::AuditQueryCache.benefit_packages_for(2023)
    @queue.subscribe(:block => true, :manual_ack => true) do |delivery_info, properties, payload|
      headers = properties.headers || {}
      person_id = headers["person_id"]
      execute_audit(person_id, @channel, delivery_info)
    end
  end

  def publish_response(person_id, response, code)
    out_chan = @connection.create_channel
    out_chan.tx_select
    d_ex = out_chan.default_exchange
    d_ex.publish(response, 
      {
        :routing_key => self.class.result_queue_name,
        :headers => {
          :return_status => code,
          :person_id => person_id
        }
      })
    out_chan.tx_commit
    out_chan.close
  end

  def relationship_for(person, family, version_date)
    return "self" if (person.id == family.primary_applicant.person_id)
    fm_person = family.primary_applicant.person_version_for(version_date)
    return "unrelated" unless fm_person
    fm_person.person_relationships.select { |r| r.relative_id.to_s == person.id.to_s}.first.try(:kind) || "unrelated"
  end
  
  def version_in_window?(updated_at)
    (updated_at >= AUDIT_START_DATE) && (updated_at < AUDIT_END_DATE)
  end
  
  def calc_eligibility_for(cr, family, benefit_packages, ed)
    effective_date = (ed < Date.new(2023,1,1)) ? Date.new(2023,1,1) : ed.to_date
    all_eligibilities = benefit_packages.map do |hbp|
      [
        hbp,
        InsuredEligibleForBenefitRule.new(cr, hbp, {new_effective_on: effective_date, family: family, version_date: ed, market_kind: "individual"}).satisfied?
      ]
    end
    eligible_value = all_eligibilities.any? do |ae|
      ae.last.first
    end
    eligibility_error_lookups = all_eligibilities.reject do |ae|
      ae.last.first
    end
    eligibility_errors = eligibility_error_lookups.map do |eel|
      {
        package: eel.first.title,
        errors: eel.last.last
      }.to_json
    end
    [eligible_value, eligibility_errors.join("\n")]
  end
  
  def home_address_for(person)
    home_address = person.home_address
    return([nil, nil, nil, nil, nil]) if home_address.blank?
    [home_address.address_1, home_address.address_2,
     home_address.city, home_address.state, home_address.zip]
  end
  
  def mailing_address_for(person)
    return([nil, nil, nil, nil, nil]) unless person.has_mailing_address?
    home_address = person.mailing_address
    [home_address.address_1, home_address.address_2,
     home_address.city, home_address.state, home_address.zip]
  end
  
  # Discard cases where we don't have a home OR mailing address for the primary
  # We block them earlier in the process
  def primary_has_address?(person, person_version, family)
     # If I'm the primary, do I have an address on this version?
    if (person.id == family.primary_applicant.person_id)
      !(person_version.home_address.blank? && person_version.mailing_address.blank?)
    else
      !(family.primary_applicant.person.home_address.blank? && family.primary_applicant.person.mailing_address.blank?)
    end
  end
  # Exclude individuals who have not even completed the application.
  # They are blocked by the UI rules far earlier in the process.
  def primary_answered_data?(person, person_version, family)
    if (person.id == family.primary_applicant.person_id)
      primary_person = person_version
      cr = primary_person.consumer_role
      return false if cr.blank?
      lpd = cr.lawful_presence_determination
      return false if lpd.blank?
      !(lpd.citizen_status.blank? || (primary_person.is_incarcerated == nil))
    else
      primary_person = family.primary_applicant.person
      cr = primary_person.consumer_role
      return false if cr.blank?
      lpd = cr.lawful_presence_determination
      return false if lpd.blank?
      !(lpd.citizen_status.blank? || (primary_person.is_incarcerated == nil))
    end
  end
  
  # Select only if curam is not the authorization authority
  def not_authorized_by_curam?(person)
    cr = person.consumer_role
    return true if cr.blank?
    lpd = cr.lawful_presence_determination
    return true if lpd.blank?
    !(lpd.vlp_authority == "curam")
  end
  
  def auditable?(person_record, person_version, person_updated_at, family)
    version_in_window?(person_updated_at) &&
    primary_has_address?(person_record, person_version, family) &&
    primary_answered_data?(person_record, person_version, family) &&
    not_authorized_by_curam?(person_version)
  end
  
  def no_dc_address_reason_for(pers)
    return "homeless" if pers.is_homeless
    return "I am temporarily living outside of DC" if pers.is_temporarily_out_of_state
    nil
  end

  def latest_verification_type_value_for(pers, v_type)
    vt_list = pers.verification_types.reject do |vt|
      vt.type_name.blank?
    end 
    vts = vt_list.sort_by do |vt|
      if vt.updated_at
        vt.updated_at
      elsif vt.created_at
        vt.created_at
      else
        vt.id.generation_time
      end
    end
    selected_vts = vts.select do |vt|
      vt.type_name == v_type
    end
    last_verification = selected_vts.last
    return nil unless last_verification
    last_verification.validation_status
  end

  def latest_person_income_verification(pers, family, version_time)
    family_member = family.family_members.detect do |fm|
      fm.person_id == pers.id
    end
    return nil unless family_member
    determined_applications = FinancialAssistance::Application.where(family_id: family.id).determined
    existing_applications = determined_applications.select do |da|
      da.created_at <= version_time
    end
    last_application = existing_applications.sort_by(&:created_at).last
    return nil unless last_application
    applicant = last_application.applicants.detect do |appl|
      appl.family_member_id == family_member.id
    end
    return nil unless applicant
    income_evidence = applicant.income_evidence
    return nil unless income_evidence
    income_evidence.aasm_state
  end

  def execute_audit(person_id, chan, delivery_info)
    health_benefit_packages = @benefit_packages
    passive_r_date = PASSIVE_RENEWAL_DATE
    pers_record = Person.find(person_id)
    families = pers_record.families
    t_file = Tempfile.new("ivl_audit")
    csv_file = t_file.path
    t_file.close
    t_file.unlink
    person_versions = Versioning::VersionCollection.new(pers_record, passive_r_date)
    error = false
    CSV.open(csv_file, "wb") do |csv|
      person_versions.each do |p_v|
        begin
          p_version = p_v.resolve_to_model
          person_updated_at = p_v.timestamp
          # This "pers" variable will be the version that is appended to the CSV
          pers = p_version
          families.each do |fam|
            cr = pers.consumer_role
            if cr
              cr.person = p_version
              begin
                if auditable?(pers_record, p_version, person_updated_at, fam)
                  eligible, eligibility_errors = calc_eligibility_for(cr, fam, health_benefit_packages, person_updated_at)
                  lpd = cr.lawful_presence_determination
                  if lpd
                    address_fields = home_address_for(pers)
                    mailing_address_fields = mailing_address_for(pers)
                    csv << ([
                      fam.id,
                      pers.hbx_id,
                      pers.last_name,
                      pers.first_name,
                      pers.full_name,
                      pers.dob,
                      pers.gender,
                      person_updated_at.strftime("%Y-%m-%d %H:%M:%S.%L"),
                      (pers_record.id == fam.primary_applicant.person_id),
                      relationship_for(pers_record, fam, person_updated_at),
                      lpd.citizen_status,
                      (lpd.citizen_status.nil? ? nil : (lpd.citizen_status == "indian_tribe_member")),
                      pers.is_incarcerated] +
                      address_fields +
                      mailing_address_fields +
                      [
                        !no_dc_address_reason_for(pers).blank?,
                        no_dc_address_reason_for(pers),
                        cr.is_applying_coverage,
                        pers.resident_role.present?,
                        latest_verification_type_value_for(pers, "Citizenship"), # Citizenship Status
                        latest_verification_type_value_for(pers, "Immigration status"), # Immigration Status
                        latest_verification_type_value_for(pers, "Social Security Number"), # Social Security Status 
                        latest_person_income_verification(pers, fam, person_updated_at), # Income Verification
                        eligible,
                        eligible ? "" : eligibility_errors
                    ])
                  end
                end          
              rescue Mongoid::Errors::DocumentNotFound => e
                publish_response(person_id, e.inspect + "\n\n" + e.backtrace.inspect, "500")
                chan.acknowledge(delivery_info.delivery_tag, false)
                error = true
                break
              end
            end
          end
        rescue HistoryTrackerReversalError => htre
          publish_response(person_id, htre.inspect + "\n\n" + htre.backtrace.inspect, "500")
          chan.acknowledge(delivery_info.delivery_tag, false)
          error = true
          break
        rescue Exception => x
          publish_response(person_id, x.inspect + "\n\n" + x.backtrace.inspect, "500")
          chan.acknowledge(delivery_info.delivery_tag, false)
          error = true
          break
        end
      end
    end
    unless error
      File.open(csv_file, "rb") do |f|
        data = f.read
        data ||= ""
        if data.strip.blank?
          publish_response(person_id, data, "204")
        else
          publish_response(person_id, data, "200")
        end
      end
      chan.acknowledge(delivery_info.delivery_tag, false)
    end
  end
end


# The following two overrides prevent database writing by Mongoid
class Mongo::Collection
  def update_one(filter, update, options = {})
    #puts caller
    #raise update.inspect
  end

  def update_many(filter, update, options = {})
    #puts caller
    #raise update.inspect
  end
end

class Mongo::Collection::View
  def update_one(filter, update, options = {})
    #puts caller
    #raise update.inspect
  end

  def update_many(filter, update, options = {})
    #puts caller
    #raise update.inspect
  end
end

PersonAuditListener.run