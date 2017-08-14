class ShopBrokerNotices::BrokerHiredNotice < ShopBrokerNotice
  Required= Notice::Required + []

  attr_accessor :broker
  attr_accessor :employer_profile
  
  def initialize(employer_profile,args={})
    self.employer_profile = employer_profile
    self.broker = employer_profile.broker_agency_profile.primary_broker_role.person
    args[:recipient] = broker
    args[:market_kind]= 'shop'
    args[:notice] = PdfTemplates::BrokerNotice.new
    args[:to] = broker.work_email_or_best
    args[:name] = broker.full_name
    args[:recipient_document_store] = broker
    self.header = "notices/shared/shop_header.html.erb"
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
      full_name: broker.full_name.titleize,
      hbx_id: broker.hbx_id,
      assignment_date: employer_profile.broker_agency_accounts.detect{|br| br.is_active == true}.start_on
    })
    notice.primary_fullname = broker.full_name
    notice.er_legal_name = employer_profile.legal_name.titleize
    notice.er_first_name = employer_profile.staff_roles.first.first_name
    notice.er_last_name = employer_profile.staff_roles.first.last_name
    notice.broker_agency = employer_profile.broker_agency_profile.legal_name.titleize
    append_address(employer_profile.broker_agency_profile.organization.primary_office_location.address)
    append_hbe
  end

end

