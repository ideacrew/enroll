class ShopBrokerNotices::BrokerFiredNotice < Notice
  Required= Notice::Required + []

  attr_accessor :broker
  attr_accessor :employer_profile

  def initialize(employer_profile, args = {})
    self.employer_profile = employer_profile
    broker_agency_account = employer_profile.broker_agency_accounts.unscoped.select{ |b| b.is_active == false}.sort_by(&:created_at).last
    broker_role = broker_agency_account.broker_agency_profile.primary_broker_role.person
    self.broker = broker_role
    args[:recipient] = broker
    args[:market_kind]= 'shop'
    args[:notice] = PdfTemplates::BrokerNotice.new
    args[:to] = broker.work_email_or_best
    args[:name] = broker.full_name
    args[:recipient_document_store] = broker
    self.header = "notices/shared/header_with_page_numbers.html.erb"
    super(args)
  end


  def deliver
    build
    generate_pdf_notice
    attach_envelope
    non_discrimination_attachment
    upload_and_send_secure_message
    send_generic_notice_alert
  end

   def build
    broker_agency_account = employer_profile.broker_agency_accounts.unscoped.select{ |b| b.is_active == false}.sort_by(&:created_at).last
    notice.primary_fullname = broker.full_name.titleize
    notice.first_name = broker.first_name.titleize
    notice.last_name = broker.last_name.titleize
    notice.hbx_id = broker.hbx_id
    notice.mpi_indicator = self.mpi_indicator
    notice.employer_name = employer_profile.legal_name.titleize
    notice.employer_first_name = employer_profile.staff_roles.first.first_name.titleize
    notice.employer_last_name = employer_profile.staff_roles.first.last_name.titleize
    notice.termination_date = broker_agency_account.end_on
    notice.broker_agency = broker_agency_account.broker_agency_profile.legal_name.titleize
    append_address(broker_agency_account.broker_agency_profile.organization.primary_office_location.address)
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

end
