class ShopBrokerNotice < Notice

  Required= Notice::Required + []

  attr_accessor :broker
  attr_accessor :employer_profile

  def initialize(args = {})
    super(args)
  end

  def attach_envelope
    join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', 'envelope_without_address.pdf')]
  end

  def non_discrimination_attachment
    join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', 'shop_non_discrimination_attachment.pdf')]
  end

  def append_address(address)
    notice.primary_address = PdfTemplates::NoticeAddress.new({
                                 street_1: address.address_1.titleize,
                                 street_2: address.address_2.titleize,
                                 city: address.city.titleize,
                                 state: address.state,
                                 zip: address.zip
                             })
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