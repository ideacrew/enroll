class GeneralAgencyNotices::GeneralAgencyTerminatedNotice < GeneralAgencyNotice
	Required= Notice::Required + []

  attr_accessor :broker
  attr_accessor :employer_profile
  attr_accessor :general_agency
  attr_accessor :broker_agency_profile

  def initialize(employer_profile, args = {})
    self.employer_profile = employer_profile
    self.general_agency = self.employer_profile.general_agency_accounts.inactive.last
    broker_role = self.employer_profile.broker_agency_accounts.unscoped.last.broker_agency_profile.primary_broker_role.person
    self.broker = broker_role
    args[:recipient] = general_agency.general_agency_profile
    args[:market_kind]= 'shop'
    args[:notice] = PdfTemplates::GeneralAgencyNotice.new
    args[:to] = broker.work_email_or_best
    args[:name] = general_agency.ga_name
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
    notice.primary_fullname = general_agency.ga_name.titleize
    notice.hbx_id = broker.hbx_id
    notice.mpi_indicator = self.mpi_indicator
    notice.employer_name = employer_profile.legal_name.titleize
    notice.employer_first_name = employer_profile.staff_roles.first.first_name.titleize
    notice.employer_last_name = employer_profile.staff_roles.first.last_name.titleize
    notice.employer_email = employer_profile.staff_roles.first.emails.first.address
    notice.broker_agency = employer_profile.broker_agency_accounts.unscoped.last.broker_agency_profile.legal_name.titleize
    append_hbe
    append_address(general_agency.general_agency_profile.organization.primary_office_location.address)
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
