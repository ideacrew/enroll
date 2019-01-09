class ShopBrokerNotice < Notice

  Required= Notice::Required + []

  attr_accessor :broker
  attr_accessor :employer_profile

  def initialize(employer_profile, args = {})
    super(args)
  end

  def attach_envelope
    join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', 'ma_envelope_without_address.pdf')]
  end

  def non_discrimination_attachment
    join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', 'ma_shop_non_discrimination_attachment.pdf')]
  end

  def employer_appeal_rights_attachment
    join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', 'ma_employer_appeal_rights.pdf')]
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

  def upload_and_send_secure_message
    doc_uri = upload_to_amazonS3
    notice = create_recipient_document(doc_uri)
    create_secure_inbox_message(notice)
  end

  def create_secure_inbox_message(notice)
    body = "<br>You can download the notice by clicking this link " +
        "<a href=" + "#{Rails.application.routes.url_helpers.authorized_document_download_path(recipient.class.to_s,
                                                                                               recipient.id, 'documents', notice.id )}?content_type=#{notice.format}&filename=#{notice.title.gsub(/[^0-9a-z]/i,'')}.pdf&disposition=inline" + " target='_blank'>" + notice.title + "</a>"
    message = recipient.inbox.messages.build({ subject: subject, body: body, from: employer_profile.legal_name })
    message.save!
  end

  def append_hbe
    notice.hbe = PdfTemplates::Hbe.new({
                   url: "www.dhs.dc.gov",
                   phone: "(855) 532-5465",
                   fax: "(855) 532-5465",
                   email: "#{Settings.contact_center.email_address}"
               })
  end
end
