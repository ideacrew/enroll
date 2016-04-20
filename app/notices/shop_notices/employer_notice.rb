class ShopNotices::EmployerNotice < ShopNotices::ShopPdfNotice

  def initialize(employer_profile, args = {})
    super(args)
    @employer_profile = employer_profile
    @template = args[:template]
    @delivery_method = args[:delivery_method].split(',')
    @employer_contact = @employer_profile.staff_roles.first
    # @to = @employer_contact.home_email.address

    # @email_notice = args[:email_notice] || true
    # @paper_notice = args[:paper_notice] || true
  end

  # def deliver
  #   # send_email_notice if @email_notice
  #   # send_pdf_notice if @paper_notice
  #   # send_email_notice
  #   super
  # end

  def build
    @notice = PdfTemplates::EmployerNotice.new

    @notice.primary_fullname = @employer_contact.full_name.titleize
    @notice.primary_identifier = @employer_profile.hbx_id

    # @notice.open_enrollment_end_on = employer_profile.try(:active_plan_year).try(:open_enrollment_end_on)
    # @notice.coverage_end_on = employer_profile.try(:active_plan_year).try(:end_on)
    # @notice.coverage_start_on = employer_profile.plan_years.sort_by{|start_on| start_on}.last.start_on

    # if @employer_contact.mailing_address.present?

    append_primary_address(@employer_contact.mailing_address)

    # else
    #   append_primary_address(employer_profile.organization.try(:primary_office_location).try(:address))
    # end

    append_hbe
    append_broker(@employer_profile.broker_agency_profile)
  end
end 
