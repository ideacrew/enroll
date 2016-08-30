class ShopNotices::EmployerNotice < ShopNotice

  attr_accessor :employer_profile,:trigger_type

  Required= ShopNotice::Required + [:employer_profile]

  def initialize(args = {})
    self.employer_profile=args[:employer_profile]
    self.trigger_type = args[:trigger_type]
    person= employer_profile.staff_roles.first
    args[:recipient] = employer_profile
    args[:market_kind]= 'shop'
    args[:notice] = PdfTemplates::EmployerNotice.new
    args[:to] = person.work_email.try(:address) || person.home_email.try(:address)
    args[:name] = "testing"
    args[:recipient_document_store]= employer_profile
    super(args)
    
    # @email_notice = args[:email_notice] || true
    # @paper_notice = args[:paper_notice] || true
  end

  def deliver
    # send_email_notice if @email_notice
    # send_pdf_notice if @paper_notice
    # send_email_notice
    build
    super
  end

  def build
    notice.trigger_type = self.trigger_type
    notice.primary_fullname = "Lydia Austin"
    notice.employer_name = ""
    notice.primary_identifier = ""
    append_address(employer_profile.organization.primary_office_location.address)
    # @notice.open_enrollment_end_on = employer_profile.try(:active_plan_year).try(:open_enrollment_end_on)
    # @notice.coverage_end_on = employer_profile.try(:active_plan_year).try(:end_on)
    # @notice.coverage_start_on = employer_profile.plan_years.sort_by{|start_on| start_on}.last.start_on
    # if @recipient.mailing_address.present?

    # append_primary_address(recipient.mailing_address || employer_profile.organization.office_locations.first.address)

    # else
    #   append_primary_address(employer_profile.organization.try(:primary_office_location).try(:address))
    # end

    append_hbe
    append_broker(employer_profile.broker_agency_profile)
  end

  def append_address(primary_address)
    notice.primary_address = PdfTemplates::NoticeAddress.new({
      street_1: "609 H St, NE",
      street_2: "Suite 200",
      city: "Washington",
      state: "DC",
      zip: "20092"
      })
  end

end 
