# frozen_string_literal: true

class Enrollments::IndividualMarket::OpenEnrollmentBegin
  # Active IVL hbx enrollments
  # without a termination date in the current year
  # kind 'individual'
  # health || dental
  # effective on >= 1/1/2016
  # terminated_on.blank? || terminated_on > 12/31/2016
  # hbx sponsored benefit
  # Unassisted, Assisted, CSR Assisted, Catastrophic
  # Responsible party
  # :$or => [
  #   :terminated_on.lte => HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period.end_on,
  #   :terminated_on => nil
  # ]
  # TODO: Move aged off people from immedidate coverage household to extended coverage household on the day new benefit coverage period begin.

  def initialize
    @logger = Logger.new("#{Rails.root}/log/ivl_open_enrollment_begin_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
  end

  def process_renewals
    @logger.info "Started process at #{Time.now.in_time_zone('Eastern Time (US & Canada)').strftime('%m-%d-%Y %H:%M')}"
    process_ivl_osse_renewals if renewal_benefit_coverage_period.eligibility_for("aca_ivl_osse_eligibility_#{renewal_effective_on.year}".to_sym, renewal_effective_on)
    process_qhp_renewals
    @logger.info "Process ended at #{Time.now.in_time_zone('Eastern Time (US & Canada)').strftime('%m-%d-%Y %H:%M')}"
  end

  def kollection(kind, coverage_period)
    {
      :kind.in => ['individual', 'coverall'],
      :aasm_state.in => (HbxEnrollment::ENROLLED_STATUSES - ["coverage_renewed", "coverage_termination_pending"]),
      :coverage_kind.in => kind,
      :effective_on => { "$gte" => coverage_period.start_on, "$lt" => coverage_period.end_on}
    }
  end

  def current_benefit_sponsorship
    @current_benefit_sponsorship ||= HbxProfile.current_hbx.benefit_sponsorship
  end

  def renewal_benefit_coverage_period
    @renewal_benefit_coverage_period ||= current_benefit_sponsorship.renewal_benefit_coverage_period
  end

  def current_benefit_coverage_period
    @current_benefit_coverage_period ||= current_benefit_sponsorship.current_benefit_coverage_period
  end

  def renewal_effective_on
    @renewal_effective_on ||= renewal_benefit_coverage_period.start_on
  end

  def fetch_role(person)
    if person.has_active_resident_role?
      person.resident_role
    elsif person.has_active_consumer_role?
      person.consumer_role
    end
  end

  def process_ivl_osse_renewals
    @osse_renewal_failed_families = []
    Person.where({
                   '$or' => [
                     { 'consumer_role' => { '$exists' => true } },
                     { 'resident_role' => { '$exists' => true } }
                   ]
                 }).no_timeout.each do |person|
      role = fetch_role(person)
      next if role.blank?

      osse_eligibility = role.is_osse_eligibility_satisfied?(renewal_effective_on - 1.day)

      result = ::Operations::IvlOsseEligibilities::CreateIvlOsseEligibility.new.call(
        {
          subject: role.to_global_id,
          evidence_key: :ivl_osse_evidence,
          evidence_value: osse_eligibility.to_s,
          effective_date: renewal_effective_on
        }
      )

      unless result.success?
        @osse_renewal_failed_families << person.families.map(&:id)
        @logger.info "Failed Osse Renewal: #{person.hbx_id}; Error: #{result.failure}"
      end
    rescue StandardError => e
      @logger.info "Failed Osse Renewal: #{person.hbx_id}; Exception: #{e.inspect}"
    end
    @osse_renewal_failed_families.flatten!.uniq!
  end

  def process_qhp_renewals
    query = kollection(HbxEnrollment::COVERAGE_KINDS, current_benefit_coverage_period)
    family_ids = HbxEnrollment.where(query).pluck(:family_id).uniq

    if @osse_renewal_failed_families.present?
      @logger.info "Renewals not generated as they failed osse renewal: #{@osse_renewal_failed_families}"
      family_ids -= @osse_renewal_failed_families
    end

    @logger.info "Families count #{family_ids.count}"
    count = 0
    family_ids.each do |family_id|
      family = Family.find(family_id.to_s)
      primary_hbx_id = family.primary_applicant.person.hbx_id
      begin
        enrollments = family.active_household.hbx_enrollments.where(query).order(:effective_on.desc)
        enrollments.each do |enrollment|
          count += 1
          @logger.info "Found #{count} enrollments" if count % 100 == 0
          result = ::Operations::Individual::RenewEnrollment.new.call(hbx_enrollment: enrollment,
                                                                      effective_on: renewal_effective_on)
          result.failure? ? result.failure : result.success
        end
      rescue Exception => e
        @logger.info "Failed ECaseId: #{family.e_case_id} Primary: #{primary_hbx_id} Exception: #{e.inspect}"
      end
    end
  end
end
