class ShopEmployeeNotices::EmployeeMidYearPlanChange < ShopEmployeeNotice

  attr_accessor :census_employee

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
  	sep = census_employee.employee_role.person.primary_family.special_enrollment_periods.order_by(:"created_at".desc)[0]
    new_hire = census_employee.employee_role.person.primary_family.households.first.hbx_enrollments.order_by(:"created_at".desc)[0]
    effective_on = sep.present? ? sep.effective_on : new_hire.effective_on
  	notice.sep = PdfTemplates::SpecialEnrollmentPeriod.new({
      :effective_on => effective_on
      })
  end
end
