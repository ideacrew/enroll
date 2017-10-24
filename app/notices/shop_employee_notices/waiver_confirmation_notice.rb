class ShopEmployeeNotices::WaiverConfirmationNotice < ShopEmployeeNotice

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
    hbx_enrollment = census_employee.employee_role.person.primary_family.active_household.hbx_enrollments.reject{|en| en.aasm_state == "inactive"}[-1]
    covered_dependents_count = hbx_enrollment.hbx_enrollment_members.reject{ |mem| mem.is_subscriber}.count
    notice.enrollment = PdfTemplates::Enrollment.new({
      :enrollees_count => covered_dependents_count,
      :terminated_on => hbx_enrollment.terminated_on,
      :effective_on => hbx_enrollment.effective_on
      })
    notice.plan = PdfTemplates::Plan.new({
      :plan_name => hbx_enrollment.plan.name
      })
  end
end
