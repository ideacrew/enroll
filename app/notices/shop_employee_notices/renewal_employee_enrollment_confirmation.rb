class ShopEmployeeNotices::RenewalEmployeeEnrollmentConfirmation < ShopEmployeeNotice

  attr_accessor :census_employee

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
    enrollment = census_employee.renewal_benefit_group_assignment.hbx_enrollment
    notice.enrollment = PdfTemplates::Enrollment.new({
      :employer_contribution => enrollment.total_employer_contribution,
      :employee_cost => enrollment.total_employee_cost,
      :effective_on => enrollment.effective_on
      })

    plan = enrollment.plan
    notice.plan = PdfTemplates::Plan.new({
      :plan_name => plan.name
      })
  end

end
