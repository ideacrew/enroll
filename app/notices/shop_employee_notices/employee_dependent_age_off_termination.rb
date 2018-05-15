class ShopEmployeeNotices::EmployeeDependentAgeOffTermination < ShopEmployeeNotice

  attr_accessor :census_employee, :dep_hbx_ids

  def initialize(census_employee, args = {})
    self.dep_hbx_ids = args[:options][:dep_hbx_ids]
    super(census_employee, args)
  end

  def deliver
    build
    append_data
    generate_pdf_notice
    non_discrimination_attachment
    attach_envelope
    upload_and_send_secure_message
    send_generic_notice_alert
  end

  def append_data
    current_date = TimeKeeper.date_of_record
    benefit_group = census_employee.employee_role.benefit_group
    names = []
    self.dep_hbx_ids.each do |dep_id|
      names << Person.where(hbx_id: dep_id).first.full_name
    end
    notice.enrollment = PdfTemplates::Enrollment.new({
      :dependents => names,
      :terminated_on => current_date.end_of_month,
      :is_congress => benefit_group.is_congress
      })
  end
end
