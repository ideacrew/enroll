class IvlNotices::IvlBacklogVerificationNoticeUqhp < IvlNotice
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
    attach_appeals
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
    check_for_unverified_individuals
    append_hbe
    if recipient.mailing_address
      append_address(recipient.mailing_address)
    else
      raise 'mailing address not present'
    end
  end


  def check_for_unverified_individuals
    family = recipient.primary_family
    enrollments = family.households.flat_map(&:hbx_enrollments).select do |hbx_en|
      (!hbx_en.is_shop?) && (!["coverage_canceled", "shopping", "inactive"].include?(hbx_en.aasm_state)) &&
          (
          hbx_en.terminated_on.blank? ||
              hbx_en.terminated_on >= TimeKeeper.date_of_record
          )
    end
    enrollments.reject!{|e| e.coverage_terminated? }
    family_members = enrollments.inject([]) do |family_members, enrollment|
      family_members += enrollment.hbx_enrollment_members.map(&:family_member)
    end.uniq
    people = family_members.map(&:person).uniq
    outstanding_people = []
    people.each do |person|
      if person.consumer_role.outstanding_verification_types.present?
        outstanding_people << person
      end
    end
    notice.due_date = family.min_verification_due_date
    outstanding_people.uniq!
    notice.documents_needed = outstanding_people.present? ? true : false
    append_unverified_individuals(outstanding_people)
  end

  def ssn_outstanding?(person)
    person.consumer_role.outstanding_verification_types.include?("Social Security Number")
  end

  def lawful_presence_outstanding?(person)
    person.consumer_role.outstanding_verification_types.include?('Citizenship')
  end

  def immigration_status_outstanding?(person)
    person.consumer_role.outstanding_verification_types.include?('Immigration status')
  end

  def american_indian_status_outstanding?(person)
    person.consumer_role.outstanding_verification_types.include?('American Indian Status')
  end

  def residency_outstanding?(person)
    person.consumer_role.outstanding_verification_types.include?('DC Residency')
  end

  def append_unverified_individuals(people)
    people.each do |person|
      if ssn_outstanding?(person)
        notice.ssa_unverified << PdfTemplates::Individual.new({ full_name: person.full_name.titleize, documents_due_date: notice.due_date, age: person.age_on(TimeKeeper.date_of_record) })
      end

      if lawful_presence_outstanding?(person)
        notice.dhs_unverified << PdfTemplates::Individual.new({ full_name: person.full_name.titleize, documents_due_date: notice.due_date, age: person.age_on(TimeKeeper.date_of_record) })
      end

      if immigration_status_outstanding?(person)
        notice.immigration_unverified << PdfTemplates::Individual.new({ full_name: person.full_name.titleize, documents_due_date: notice.due_date, age: person.age_on(TimeKeeper.date_of_record) })
      end

      if american_indian_status_outstanding?(person)
        notice.american_indian_unverified  << PdfTemplates::Individual.new({ full_name: person.full_name.titleize, documents_due_date: notice.due_date, age: person.age_on(TimeKeeper.date_of_record) })
      end

      if residency_outstanding?(person)
        notice.residency_inconsistency  << PdfTemplates::Individual.new({ full_name: person.full_name.titleize, documents_due_date: notice.due_date, age: person.age_on(TimeKeeper.date_of_record) })
      end
    end
  end


  def append_data
    notice.notification_type = self.event_name
    notice.mpi_indicator = self.mpi_indicator
    notice.primary_identifier = recipient.hbx_id
    notice.coverage_year = TimeKeeper.date_of_record.year
    notice.current_year = TimeKeeper.date_of_record.year
    notice.primary_fullname = recipient.full_name.titleize || ""
    notice.primary_firstname = recipient.first_name.titleize
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