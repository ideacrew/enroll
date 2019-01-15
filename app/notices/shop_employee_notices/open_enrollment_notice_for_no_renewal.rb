class ShopEmployeeNotices::OpenEnrollmentNoticeForNoRenewal < ShopEmployeeNotice

  attr_accessor :census_employee

  def deliver
    build
    append_data
    generate_pdf_notice
    attach_envelope
    upload_and_send_secure_message
    send_generic_notice_alert
  end

  def append_data
    aasm_states = ["draft", "approved", "enrollment_open", "enrollment_eligible", "pending"]
    renewing_plan_year = census_employee.employer_profile.benefit_applications.where(:predecessor_id => {:$exists => true}, :aasm_state.in => aasm_states).first
    notice.plan_year = PdfTemplates::PlanYear.new({
      :start_on => renewing_plan_year.start_on,
      :open_enrollment_end_on => renewing_plan_year.open_enrollment_end_on
      })
    enrollment = census_employee.active_benefit_group_assignment.hbx_enrollments.first
    notice.plan = PdfTemplates::Plan.new({
      :plan_name => enrollment.product.name
      })
  end

end