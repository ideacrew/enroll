class ShopBrokerNotice < Notice

  Required= Notice::Required + []

  attr_accessor :broker_profile
  attr_accessor :employer_profile

  def initialize(employer_profile, args = {})
    self.employer_profile = employer_profile
    self.broker_profile = employer_profile.broker_agency_profile
    args[:recipient] = broker_profile
    args[:market_kind]= 'shop'
    args[:notice] = PdfTemplates::BrokerNotice.new
    args[:to] = employer_profile.broker_agency_profile.primary_broker_role.email_address
    args[:name] = employer_profile.broker_agency_profile.primary_broker_role.person.full_name
    args[:recipient_document_store] = employer_profile.broker_agency_profile.primary_broker_role.person
    self.header = "notices/shared/header_with_page_numbers.html.erb"
    super(args)
  end

  def deliver
    build
    generate_pdf_notice
    non_discrimination_attachment
    attach_envelope
    upload_and_send_secure_message
    send_generic_notice_alert
  end

  def build
    notice.mpi_indicator = self.mpi_indicator
    notice.broker = PdfTemplates::Broker.new({
      full_name: broker_profile.primary_broker_role.person.full_name.titleize,
      hbx_id: broker_profile.primary_broker_role.person.hbx_id,
      assignment_date: employer_profile.broker_agency_accounts.detect{|br| br.is_active == true}.start_on
    })

    notice.primary_fullname = broker_profile.primary_broker_role.person.full_name
    notice.er_legal_name = employer_profile.legal_name.titleize
    notice.er_first_name = employer_profile.staff_roles.first.first_name
    notice.er_last_name = employer_profile.staff_roles.first.last_name
    
    notice.broker_agency = broker_profile.legal_name.titleize
    append_address(employer_profile.broker_agency_profile.organization.primary_office_location.address)
    # address = broker_profile.primary_broker_role.person.mailing_address if broker_profile.primary_broker_role.person.mailing_address.present?
    #append_address(address)
    append_hbe

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


  def attach_envelope
    join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', 'envelope_without_address.pdf')]
  end

  def non_discrimination_attachment
    join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', 'shop_non_discrimination_attachment.pdf')]
  end

  def append_address(primary_address)
    notice.primary_address = PdfTemplates::NoticeAddress.new({
                                                                 street_1: primary_address.address_1.titleize,
                                                                 street_2: primary_address.address_2.titleize,
                                                                 city: primary_address.city.titleize,
                                                                 state: primary_address.state,
                                                                 zip: primary_address.zip
                                                             })
  end
end