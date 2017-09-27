class ShopEmployeeNotices::EmployeeTerminatingCoverageConfirmation < ShopEmployeeNotice
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
    terminated_enrollment = census_employee.published_benefit_group_assignment.hbx_enrollments.detect{ |h| h.aasm_state == 'coverage_termination_pending'}
    plan = terminated_enrollment.plan
    notice.plan = PdfTemplates::Plan.new({
                                             :plan_name => plan.name
                                         })
    notice.enrollment = PdfTemplates::Enrollment.new({
      :terminated_on => terminated_enrollment.terminated_on,
      :coverage_kind => terminated_enrollment.coverage_kind
      })
  end

end