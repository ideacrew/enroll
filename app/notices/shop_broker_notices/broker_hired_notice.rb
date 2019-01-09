class ShopBrokerNotices::BrokerHiredNotice < ShopBrokerNotice
  Required= Notice::Required + []
  include ::BenefitSponsors::InvoiceHelper

  attr_accessor :broker
  attr_accessor :employer_profile
  
  def initialize(broker_role,args={})
    self.employer_profile = args[:options][:event_object]
    self.broker = broker_role.person
    args[:recipient] = broker
    args[:market_kind]= 'shop'
    args[:notice] = PdfTemplates::BrokerNotice.new
    args[:to] = broker.work_email_or_best
    args[:name] = broker.full_name
    args[:recipient_document_store] = broker
    self.header = "notices/shared/header_with_page_numbers.html.erb"
    super(self.employer_profile, args)
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
      assignment_date: employer_profile.broker_agency_accounts.detect{|br| br.is_active == true}.start_on
    })
    notice.employer_name = employer_profile.legal_name.titleize
      notice.employer = PdfTemplates::EmployerStaff.new({
            employer_first_name: employer_profile.staff_roles.first.first_name,
            employer_last_name: employer_profile.staff_roles.first.last_name,
            employer_email: employer_profile.staff_roles.first.work_email_or_best,

    })
    notice.primary_fullname = broker.full_name
    notice.broker_agency = employer_profile.broker_agency_profile.legal_name.titleize
    organization = employer_profile.broker_agency_profile.organization
    address = mailing_or_primary_address(employer_profile.broker_agency_profile)
    append_address(address)
    append_hbe
  end

end

