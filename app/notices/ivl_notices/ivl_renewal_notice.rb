class IvlNotices::IvlRenewalNotice < IvlNotice
  attr_accessor :family, :data

  def initialize(consumer_role, args = {})
    args[:recipient] = consumer_role.person.families.first.primary_applicant.person
    args[:notice] = PdfTemplates::ConditionalEligibilityNotice.new
    args[:market_kind] = 'individual'
    args[:recipient_document_store]= consumer_role.person.families.first.primary_applicant.person
    args[:to] = consumer_role.person.families.first.primary_applicant.person.work_email_or_best
    self.data = args[:data]
    self.header = "notices/shared/header_ivl.html.erb"
    super(args)
  end

  def deliver
    build
    generate_pdf_notice
    attach_blank_page
    attach_non_discrimination
    attach_taglines
    attach_voter_application
    upload_and_send_secure_message

    if recipient.consumer_role.can_receive_electronic_communication?
      send_generic_notice_alert
    end

    if recipient.consumer_role.can_receive_paper_communication?
      store_paper_notice
    end
  end

  def build
    append_hbe
    notice.notification_type = self.event_name
    notice.mpi_indicator = self.mpi_indicator
    notice.coverage_year = TimeKeeper.date_of_record.next_year.year
    family = recipient.primary_family
    append_data
    notice.primary_fullname = recipient.full_name.titleize || ""
    if recipient.mailing_address
      append_address(recipient.mailing_address)
    else  
      # @notice.primary_address = nil
      raise 'mailing address not present' 
    end
  end

  def append_open_enrollment_data
    hbx = HbxProfile.current_hbx
    bc_period = hbx.benefit_sponsorship.benefit_coverage_periods.detect { |bcp| bcp if bcp.start_on.year.to_s == notice.coverage_year }
    notice.ivl_open_enrollment_start_on = bc_period.open_enrollment_start_on
    notice.ivl_open_enrollment_end_on = bc_period.open_enrollment_end_on
  end

  def append_data
    append_open_enrollment_data
    notice.individuals = data.collect do |datum|
      person = Person.where(:hbx_id => datum["policy.subscriber.person.hbx_id"]).first
      PdfTemplates::Individual.new({
        :first_name => person.first_name,
        :full_name => person.full_name,
        :incarcerated=> datum["policy.subscriber.person.is_incarcerated"] == "TRUE" ? "Yes" : "No",#Per Sarah, for blank incarceration, fill in FALSE
        :citizen_status=> citizen_status(datum["policy.subscriber.person.citizen_status"]),
        :residency_verified => datum["policy.subscriber.person.is_dc_resident?"].try(:upcase) == "TRUE"  ? "Yes" : "No"
      })
    end
  end

  def citizen_status(status)
    case status
    when "us_citizen"
      "US Citizen"
    when "alien_lawfully_present"
      "Lawfully Present"
    when "indian_tribe_member"
      "US Citizen"
    when "lawful_permanent_resident"
      "Lawfully Present"
    when "naturalized_citizen"
      "US Citizen"
    else
      "Ineligible Immigration Status"
    end
  end

end