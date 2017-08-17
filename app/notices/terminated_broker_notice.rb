class TerminatedBrokerNotice < Notice
  Required= Notice::Required
  attr_accessor :employer_profile, :broker_agency_profile, :terminated_broker_account

  def initialize(employer_profile, args = {})
    self.employer_profile = employer_profile
    self.broker_agency_profile = employer_profile.broker_agency_accounts.unscoped.select {|a| a.end_on.present?}.last.broker_agency_profile
    self.terminated_broker_account = employer_profile.broker_agency_accounts.unscoped.select {|a| a.end_on.present?}.last
    args[:recipient] = broker_agency_profile
    args[:market_kind]= 'shop'
    args[:notice] = PdfTemplates::Broker.new
    args[:to] = broker_agency_profile.try(:legal_name)
    args[:name] = broker_agency_profile.try(:legal_name)
    args[:recipient_document_store]= broker_agency_profile.try(:primary_broker_role).try(:person)
    self.header = "notices/shared/shop_header.html.erb"
    super(args)
  end

  def deliver
    build
    generate_pdf_notice
    non_discrimination_attachment
    attach_envelope
    upload_and_send_secure_message
  end

  def attach_envelope
    join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', 'envelope_without_address.pdf')]
  end

  def non_discrimination_attachment
    join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', 'shop_non_discrimination_attachment.pdf')]
  end

  def upload_and_send_secure_message
    doc_uri = upload_to_amazonS3
    notice = create_recipient_document(doc_uri)
    create_secure_inbox_message(notice)
  end

  def create_secure_inbox_message(notice)
    body = "<br>You can download the notice by clicking this link " + "<a href=" + "#{Rails.application.routes.url_helpers.authorized_document_download_path(recipient.class.to_s, recipient.id, 'documents', notice.id)}?content_type=#{notice.format}&filename=#{notice.title.gsub(/[^0-9a-z]/i, '')}.pdf&disposition=inline" + " target='_blank'>" + notice.title + "</a>"
    message = recipient.inbox.messages.build({to: broker_agency_profile.try(:full_name), sender_id: employer_profile.try(:id), parent_message_id: broker_agency_profile.id, folder: Message::FOLDER_TYPES[:inbox], subject: "You have been removed as a Broker by #{employer_profile.try(:legal_name)}", body: body, from: employer_profile.try(:legal_name)})
    message.save!
  end

  def build
    append_address(broker_agency_profile.organization.primary_office_location.address)
    append_hbe
    append_broker(broker_agency_profile)
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

  def append_address(primary_address)
    notice.primary_address = PdfTemplates::NoticeAddress.new({
                                                                 street_1: primary_address.address_1.titleize,
                                                                 street_2: primary_address.address_2.titleize,
                                                                 city: primary_address.city.titleize,
                                                                 state: primary_address.state,
                                                                 zip: primary_address.zip
                                                             })
  end

  def append_broker(broker)
    return if broker.blank?
    location = broker.organization.primary_office_location
    broker_role = broker.primary_broker_role
    person = broker_role.person if broker_role
    return if person.blank? || location.blank?
    notice.broker_first_name = person.first_name
    notice.broker_last_name = person.last_name
    notice.primary_fullname = self.broker_agency_profile.try(:legal_name)
    notice.organization = broker.legal_name
    notice.phone = location.phone.try(:to_s)
    notice.email = (person.home_email || person.work_email).try(:address)
    notice.web_address = broker.home_page
    notice.mpi_indicator = self.mpi_indicator
    notice.employer_profile = self.employer_profile
    notice.broker_agency_profile = self.broker_agency_profile
    notice.terminated_broker_account = self.terminated_broker_account
    notice.employer_name = self.employer_profile.try(:legal_name)
    # notice.broker_address = PdfTemplates::NoticeAddress.new({
    #                                                             street_1: location.address.address_1,
    #                                                             street_2: location.address.address_2,
    #                                                             city: location.address.city,
    #                                                             state: location.address.state,
    #                                                             zip: location.address.zip
    #                                                         })
  end

end
