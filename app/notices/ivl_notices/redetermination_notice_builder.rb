class IvlNotices::RedeterminationNoticeBuilder < IvlNotice

  def initialize(consumer_role, args = {})
    args[:recipient] = consumer_role.person
    args[:notice] = PdfTemplates::ConditionalEligibilityNotice.new
    args[:market_kind] = 'individual'
    args[:recipient_document_store]= consumer_role.person
    args[:to] = consumer_role.person.work_email_or_best
    self.header = "notices/shared/header_ivl.html.erb"
    super(args)
  end

  def build
    append_data
    notice.mpi_indicator = self.mpi_indicator
    notice.primary_fullname = recipient.full_name.titleize || ""
    notice.primary_firstname = recipient.first_name.titleize || ""
    if recipient.mailing_address
      append_address(recipient.mailing_address)
    else
      # @notice.primary_address = nil
      raise 'mailing address not present'
    end
  end

  def deliver
    append_hbe
    build
    generate_pdf_notice
    attach_blank_page(notice_path)
   
    if recipient.consumer_role.can_receive_electronic_communication?
      send_generic_notice_alert
    end

    if recipient.consumer_role.can_receive_paper_communication?
      store_paper_notice
    end
  end

  def append_family_members(person)
    reason_for_ineligibility = []
    reason_for_ineligibility << "this person isn’t a resident of the District of Columbia. Go to healthcare.gov to learn how to apply for coverage in the right state." if !person.is_dc_resident?
    reason_for_ineligibility << "this person is currently serving time in jail or prison for a criminal conviction." if person.is_incarcerated
    reason_for_ineligibility << "this person doesn’t have an eligible immigration status, but may be eligible for a local medical assistance program called the DC Health Care Alliance. For more information, please contact #{Settings.site.short_name} at #{notice.hbe.phone}." if lawful_presence_outstanding?(person)
    enrollment.hbx_enrollment_members.map(&:person).uniq.each do |p|
      PdfTemplates::Individual.new({
        first_name: person.first_name.titleize,
        full_name: person.full_name.titleize,
        :age => person.age_on(TimeKeeper.date_of_record),
        :reason_for_ineligibility =>  reason_for_ineligibility
      })
    end
  end

end
