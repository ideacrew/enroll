class EmployeeTerminatingCoverage < Notice

  Required= Notice::Required + []

  attr_accessor :census_employee

  def initialize(census_employee, args = {})
    self.census_employee = census_employee
    args[:recipient] = census_employee.employer_profile
    args[:market_kind]= 'shop'
    args[:notice] = PdfTemplates::EmployerNotice.new
    args[:to] = census_employee.employer_profile.staff_roles.first.work_email_or_best
    args[:name] = census_employee.employer_profile.staff_roles.first.full_name.titleize
    args[:recipient_document_store]= census_employee.employer_profile
    self.header = "notices/shared/header_with_page_numbers.html.erb"
    super(args)
  end

  def deliver
    build
    append_data
    generate_pdf_notice
    attach_envelope
    non_discrimination_attachment
    upload_and_send_secure_message
    send_generic_notice_alert
  end

  def append_data
    terminated_enrollment = census_employee.published_benefit_group_assignment.hbx_enrollments.detect{ |h| h.aasm_state == 'coverage_termination_pending'}
    notice.enrollment = PdfTemplates::Enrollment.new({
      :terminated_on => terminated_enrollment.terminated_on,
      :enrolled_count => terminated_enrollment.humanized_dependent_summary
      })
  end

  def build
    notice.notification_type = self.event_name
    notice.mpi_indicator = self.mpi_indicator
    notice.primary_fullname = census_employee.employer_profile.staff_roles.first.full_name.titleize
    notice.employee_fullname = census_employee.full_name.titleize
    notice.employer_name = recipient.organization.legal_name.titleize
    notice.primary_identifier = census_employee.employer_profile.hbx_id
    append_address(census_employee.employer_profile.organization.primary_office_location.address)
    append_broker(census_employee.employer_profile.broker_agency_profile)
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

  def append_broker(broker)
    return if broker.blank?
    location = broker.organization.primary_office_location
    broker_role = broker.primary_broker_role
    person = broker_role.person if broker_role
    return if person.blank? || location.blank? 
    notice.broker = PdfTemplates::Broker.new({
      primary_fullname: person.full_name,
      organization: broker.legal_name,
      phone: location.phone.try(:to_s),
      email: (person.home_email || person.work_email).try(:address),
      web_address: broker.home_page,
      address: PdfTemplates::NoticeAddress.new({
        street_1: location.address.address_1,
        street_2: location.address.address_2,
        city: location.address.city,
        state: location.address.state,
        zip: location.address.zip
      })
    })
  end
end