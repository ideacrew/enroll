class ShopBrokerNotices::BrokerAgencyFiredNotice < ShopBrokerNotice
  Required= Notice::Required
  attr_accessor :employer_profile, :broker_agency_profile, :terminated_broker_account

  def initialize(employer_profile, args = {})
    self.employer_profile = employer_profile
    self.broker_agency_profile = employer_profile.broker_agency_accounts.unscoped.last.broker_agency_profile
    self.terminated_broker_account = employer_profile.broker_agency_accounts.unscoped.last
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

  def build
    append_address(broker_agency_profile.organization.primary_office_location.address)
    append_broker(broker_agency_profile)
    append_hbe
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
  end

end
