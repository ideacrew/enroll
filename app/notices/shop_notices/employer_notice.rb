class ShopNotices::EmployerNotice < Notice

  attr_accessor :from, :to, :subject, :template, :notice_data

  def initialize(employer, args = {})
    super
    @employer = employer
    @to = 'raghuramg83@gmail.com'
    @template = args[:template] || "notices/shop_notices/employer_renewal"
    @email_notice = args[:email_notice] || true
    @paper_notice = args[:paper_notice] || true
  end

  def deliver
    # send_email_notice if @email_notice
    # send_pdf_notice if @paper_notice
    # send_email_notice
    #mock_notice_object
    build
    generate_pdf_notice
  end

  def mock_notice_object
    @notice = PdfTemplates::EmployerNotice.new({ 
      primary_fullname: 'Shane Levy', 
      primary_identifier: '642323233', 
      employer_name: 'Legal Inc',
      primary_address: PdfTemplates::NoticeAddress.new({
        street_1: "100 K ST NE",
        street_2: "Suite 100",
        city: "Washington DC",
        state: "DC",
        zip: "20005"
      })
    })
  end

  def build
    @notice = PdfTemplates::EmployerNotice.new

    @notice.primary_fullname = @employer.person.full_name.titleize
    employer_profile = EmployerProfile.find(@employer.employer_profile_id)
    @notice.primary_identifier = employer_profile.organization.hbx_id
    @notice.open_enrollment_end_on = employer_profile.try(:active_plan_year).try(:open_enrollment_end_on)

    if @employer.person.addresses.present?
      append_address(@employer.person.addresses[0])
    else
      append_address(employer_profile.organization.try(:primary_office_location).try(:address))
    end

    append_hbe
    append_broker(employer_profile.broker_agency_profile)
  end

  def append_hbe
    @notice.hbe = PdfTemplates::Hbe.new({
      url: "www.dhs.dc.gov",
      phone: "(855) 532-5465",
      fax: "(855) 532-5465",
      email: "info@dchealthlink.com",
      address: PdfTemplates::NoticeAddress.new({
        street_1: "100 K ST NE",
        street_2: "Suite 100",
        city: "Washington DC",
        state: "DC",
        zip: "20005"
      })
    })
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

  def append_address(primary_address)
    @notice.primary_address = PdfTemplates::NoticeAddress.new({
      street_1: primary_address.address_1.titleize,
      street_2: primary_address.address_2.titleize,
      city: primary_address.city.titleize,
      state: primary_address.state,
      zip: primary_address.zip
      })
  end
end 
