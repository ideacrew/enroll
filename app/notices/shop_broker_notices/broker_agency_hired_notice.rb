class ShopBrokerNotices::BrokerAgencyHiredNotice < ShopBrokerNotice

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
    notice.er_legal_name = employer_profile.legal_name.titleize
    notice.er_first_name = employer_profile.staff_roles.first.first_name
    notice.er_last_name = employer_profile.staff_roles.first.last_name
    notice.er_address = employer_profile.staff_roles.first.work_address_or_best
    notice.er_phone = employer_profile.staff_roles.first.work_phone_or_best
    notice.broker_agency = broker_profile.legal_name.titleize
    append_address(employer_profile.broker_agency_profile.organization.primary_office_location.address)
    append_hbe
  end
end