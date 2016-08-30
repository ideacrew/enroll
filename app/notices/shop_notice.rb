class ShopNotice < Notice

  Required= Notice::Required + []

  def initialize(params = {})
    super(params)
  end

  def deliver
    build
    generate_pdf_notice
    attach_blank_page
    prepend_envelope
    attach_voter_application
    upload_and_send_secure_message
    send_generic_notice_alert
  end

  def prepend_envelope
    envelope = Envelope.new
    envelope.fill_envelope(notice, mpi_indicator)
    envelope.render_file(envelope_path)
    join_pdfs [envelope_path, notice_path]
  end

  def attach_voter_application
    join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', 'voter_application.pdf')]
  end

  def attach_blank_page
    blank_page = Rails.root.join('lib/pdf_templates', 'blank.pdf')

    page_count = Prawn::Document.new(:template => notice_path).page_count
    if (page_count % 2) == 1
      join_pdfs [notice_path, blank_page]
    end
  end


  def append_hbe
    notice.hbe = PdfTemplates::Hbe.new({
      url: "www.dhs.dc.gov",
      phone: "(855) 532-5465",
      fax: "(855) 532-5465",
      email: "#{Settings.contact_center.email_address}",
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
    person = broker_role.person if broker_role
    return if person.blank? || location.blank?
    
    notice.broker = PdfTemplates::Broker.new({
      primary_fullname: person.full_name,
      organization: broker.legal_name,
      phone: location.phone.try(:to_s),
      email: (person.home_email || person.work_email).try(:address),
      web_address: broker.home_page,
      address: PdfTemplates::NoticeAddress.new({
        street_1: location.address.address_1,
        street_2: location.address.address_2,
        city: location.address.city,
        state: location.address.state,
        zip: location.address.zip
      })
    })
  end

  def append_primary_address(primary_address)
    notice.primary_address = PdfTemplates::NoticeAddress.new({
      street_1: "609 H St, NE",
      street_2: "Suite 200",
      city: "Washington",
      state: "DC",
      zip: "20020"
      })
  end

end
