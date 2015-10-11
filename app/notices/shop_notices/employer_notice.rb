class ShopNotices::EmployerNotice < ShopNotices::ShopPdfNotice

  def initialize(employer, args = {})
    super(args)
    @employer = employer
    @to = @employer.try(:person).try(:home_email).try(:address)
    @template = args[:template] || "notices/shop_notices/employer_renewal"
    @email_notice = args[:email_notice] || true
    @paper_notice = args[:paper_notice] || true
  end

  def deliver
    # send_email_notice if @email_notice
    # send_pdf_notice if @paper_notice
    # send_email_notice
    super
  end

  def build
    @notice = PdfTemplates::EmployerNotice.new

    @notice.primary_fullname = @employer.person.full_name.titleize
    employer_profile = EmployerProfile.find(@employer.employer_profile_id)
    @notice.primary_identifier = employer_profile.organization.hbx_id
    @notice.open_enrollment_end_on = employer_profile.try(:active_plan_year).try(:open_enrollment_end_on)
    @notice.coverage_end_on = employer_profile.try(:active_plan_year).try(:end_on)
    @notice.coverage_start_on = employer_profile.plan_years.sort_by{|start_on| start_on}.last.start_on

    if @employer.person.mailing_address.present?
      append_primary_address(@employer.person.mailing_address)
    else
      append_primary_address(employer_profile.organization.try(:primary_office_location).try(:address))
    end

    append_hbe
    append_broker(employer_profile.broker_agency_profile)
  end

  def append_broker(broker)
    return if broker.blank?

    location = broker.organization.primary_office_location
    broker_role = broker.primary_broker_role
    @notice.broker = PdfTemplates::Broker.new({
      primary_fullname: broker_role.try(:person).try(:full_name),
      organization: broker.legal_name,
      phone: location.phone.try(:to_s),
      email: broker_role.email_address,
      web_address: broker.home_page,
      address: PdfTemplates::NoticeAddress.new({
        street_1: location.try(:address).try(:address_1),
        street_2: location.try(:address).try(:address_2),
        city: location.try(:address).try(:city),
        state: location.try(:address).try(:state),
        zip: location.try(:address).try(:zip)
      })
    })
  end
end 
