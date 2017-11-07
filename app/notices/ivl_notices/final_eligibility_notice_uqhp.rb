class IvlNotices::FinalEligibilityNoticeUqhp < IvlNotice
  include ApplicationHelper
  attr_accessor :family, :data, :person

  def initialize(consumer_role, args = {})
    args[:recipient] = consumer_role.person.families.first.primary_applicant.person
    args[:notice] = PdfTemplates::ConditionalEligibilityNotice.new
    args[:market_kind] = 'individual'
    args[:recipient_document_store]= consumer_role.person.families.first.primary_applicant.person
    args[:to] = consumer_role.person.families.first.primary_applicant.person.work_email_or_best
    self.person = args[:person]
    self.data = args[:data]
    self.header = "notices/shared/header_ivl.html.erb"
    super(args)
  end

  def deliver
    build
    generate_pdf_notice
    attach_blank_page(notice_path)
    attach_required_documents if notice.documents_needed
    attach_non_discrimination
    attach_taglines
    upload_and_send_secure_message

    if recipient.consumer_role.can_receive_electronic_communication?
      send_generic_notice_alert
    end

    if recipient.consumer_role.can_receive_paper_communication?
      store_paper_notice
    end
  end

  def build
    append_data
    pick_enrollments
    append_hbe
    append_unverified_individuals
    if recipient.mailing_address
      append_address(recipient.mailing_address)
    else
      raise 'mailing address not present'
    end
  end

  def pick_enrollments
    hbx_enrollments = []
    family = recipient.primary_family
    enrollments = family.enrollments.where(:aasm_state.in => ["auto_renewing", "coverage_selected"], :kind => "individual")
    return nil if enrollments.blank?
    health_enrollments = enrollments.detect{ |e| e.coverage_kind == "health" && e.effective_on.year.to_s == notice.coverage_year}
    dental_enrollments = enrollments.detect{ |e| e.coverage_kind == "dental" && e.effective_on.year.to_s == notice.coverage_year}

    hbx_enrollments << health_enrollments
    hbx_enrollments << dental_enrollments

    return nil if hbx_enrollments.flatten.compact.empty?
    hbx_enrollments.flatten.compact.each do |enrollment|
      notice.enrollments << append_enrollment_information(enrollment)
      append_member_information(enrollment)
    end
  end

  def append_enrollment_information(enrollment)
    plan = PdfTemplates::Plan.new({
      plan_name: enrollment.plan.name,
      is_csr: enrollment.plan.is_csr?,
      coverage_kind: enrollment.plan.coverage_kind,
      plan_carrier: enrollment.plan.carrier_profile.organization.legal_name,
      family_deductible: enrollment.plan.family_deductible.split("|").last.squish,
      deductible: enrollment.plan.deductible
      })
    PdfTemplates::Enrollment.new({
      premium: enrollment.total_premium.round(2),
      aptc_amount: enrollment.applied_aptc_amount.round(2),
      responsible_amount: (enrollment.total_premium - enrollment.applied_aptc_amount.to_f).round(2),
      phone: phone_number(enrollment.plan.carrier_profile.legal_name),
      is_receiving_assistance: (enrollment.applied_aptc_amount > 0 || enrollment.plan.is_csr?) ? true : false,
      coverage_kind: enrollment.coverage_kind,
      kind: enrollment.kind,
      effective_on: enrollment.effective_on,
      plan: plan,
      enrollees: enrollment.hbx_enrollment_members.inject([]) do |enrollees, member|
        enrollee = PdfTemplates::Individual.new({
          full_name: member.person.full_name.titleize,
          age: member.person.age_on(TimeKeeper.date_of_record)
        })
        enrollees << enrollee
      end
    })
  end

  def append_member_information(enrollment)
    enrollment.hbx_enrollment_members.map(&:person).each do |person|
      notice.individuals << PdfTemplates::Individual.new({
        :first_name => person.first_name.titleize,
        :last_name => person.last_name.titleize,
        :full_name => person.full_name.titleize,
        :age => calculate_age_by_dob(person.dob),
        :incarcerated => person.is_incarcerated? ? "Yes" : "No",
        :citizen_status => citizen_status(person.citizen_status),
        :residency_verified => is_dc_resident(recipient) ? "Yes" : "No",
        :is_without_assistance => true,
        :is_totally_ineligible => is_totally_ineligible(person)
        })
    end
  end

  def append_data
    notice.notification_type = self.event_name
    notice.mpi_indicator = self.mpi_indicator
    notice.primary_identifier = recipient.hbx_id
    notice.coverage_year = TimeKeeper.date_of_record.next_year.year
    notice.current_year = TimeKeeper.date_of_record.year
    notice.ivl_open_enrollment_start_on = Settings.aca.individual_market.open_enrollment.start_on
    notice.ivl_open_enrollment_end_on = Settings.aca.individual_market.open_enrollment.end_on
    notice.primary_fullname = recipient.full_name.titleize || ""
    notice.primary_firstname = recipient.first_name.titleize
  end

  def append_unverified_individuals
    family = recipient.primary_family
    enrolled_contingent_enrollment = family.enrollments.where(:aasm_state => "enrolled_contingent").sort_by(&:created_at).last

    if enrolled_contingent_enrollment.present?# && enrolled_contingent_enrollment.special_verification_period.present?
      family_members = enrolled_contingent_enrollment.hbx_enrollment_members.map(&:family_member)
      people = family_members.map(&:person).uniq
      people.reject!{|p| p.consumer_role.aasm_state != 'verification_outstanding'}
      people.reject!{|person| !ssn_outstanding?(person) && !lawful_presence_outstanding?(person) }
      if people.empty?
        raise 'no family member found with outstanding verification'
      end

      outstanding_people = []
      people.each do |person|
        if person.consumer_role.outstanding_verification_types.present?
          outstanding_people << person
        end
      end

      outstanding_people.uniq!
      if outstanding_people.empty?
        notice.documents_needed = false
        raise 'no family member found without uploaded documents'
      else
        notice.documents_needed = true
        notice.due_date = enrolled_contingent_enrollment.special_verification_period || TimeKeeper.date_of_record+95.days
        append_outstanding_people(people)
      end
    else
      notice.documents_needed = false
      notice.due_date = nil
    end
  end

  def append_outstanding_people(people)
    people.each do |person|
      if ssn_outstanding?(person)
        notice.ssa_unverified << PdfTemplates::Individual.new({ full_name: person.full_name.titleize, documents_due_date: notice.due_date, age: person.age_on(TimeKeeper.date_of_record)})
      end

      if lawful_presence_outstanding?(person)
        notice.dhs_unverified << PdfTemplates::Individual.new({ full_name: person.full_name.titleize, documents_due_date: notice.due_date, age: person.age_on(TimeKeeper.date_of_record)})
      end
    end
  end

  def ssn_outstanding?(person)
    person.consumer_role.outstanding_verification_types.include?("Social Security Number")
  end

  def is_totally_ineligible(person)
    !is_dc_resident(recipient) && person.is_incarcerated? && ConsumerRole::INELIGIBLE_CITIZEN_VERIFICATION.include?(person.citizen_status)
  end

  def is_dc_resident(person)
    return false if person.no_dc_address == true && person.no_dc_address_reason.blank?
    return true if person.no_dc_address == true && person.no_dc_address_reason.present?

    address_to_use = person.addresses.collect(&:kind).include?('home') ? 'home' : 'mailing'
    if person.addresses.present?
      if person.addresses.select{|address| address.kind == address_to_use && address.state == 'DC'}.present?
        return true
      else
        return false
      end
    else
      return ""
    end
  end

  def phone_number(legal_name)
    case legal_name
    when "BestLife"
      "(800) 433-0088"
    when "CareFirst"
      "(855) 444-3119"
    when "Delta Dental"
      "(800) 471-0236"
    when "Dominion"
      "(855) 224-3016"
    when "Kaiser"
      "(844) 524-7370"
    end
  end

  def citizen_status(status)
    case status
    when "us_citizen"
      "US Citizen"
    when "LP"
      "Lawfully Present"
    when "NC"
      "US Citizen"
    else
      ""
    end
  end

end