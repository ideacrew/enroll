class ShopNotices::ShopPdfNotice < Notice

  def initialize(args = {})
    super(args)
  end

  def deliver
    build
    generate_pdf_notice
  end

  def append_hbe
    @notice.hbe = PdfTemplates::Hbe.new({
      url: "www.dhs.dc.gov",
      phone: "(855) 532-5465",
      fax: "(855) 532-5465",
      email: "#{Settings.contant_center.email_address}",
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

  def append_primary_address(primary_address)
    @notice.primary_address = PdfTemplates::NoticeAddress.new({
      street_1: primary_address.address_1.titleize,
      street_2: primary_address.address_2.titleize,
      city: primary_address.city.titleize,
      state: primary_address.state,
      zip: primary_address.zip
      })
  end
end
