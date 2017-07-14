class ShopEmployeeNotices::EmployeeTerminationNotice < ShopEmployeeNotice

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
    hbx = HbxProfile.current_hbx
    bc_period = hbx.benefit_sponsorship.benefit_coverage_periods.detect { |bcp| bcp if (bcp.start_on..bcp.end_on).cover?(TimeKeeper.date_of_record.next_year) }
    notice.enrollment = PdfTemplates::Enrollment.new({
                      :ivl_open_enrollment_start_on => bc_period.open_enrollment_start_on,
                      :ivl_open_enrollment_end_on => bc_period.open_enrollment_end_on
      })

    enrollments = []
    health_enrollment = census_employee.published_benefit_group_assignment.hbx_enrollments.detect{ |h| h.coverage_kind == 'health' && h.aasm_state == 'coverage_selected'}
    dental_enrollment = census_employee.published_benefit_group_assignment.hbx_enrollments.detect{ |h| h.coverage_kind == 'dental' && h.aasm_state == 'coverage_selected'}
    enrollments << health_enrollment
    enrollments << dental_enrollment
    notice.census_employee = PdfTemplates::CensusEmployee.new({
      :date_of_termination => census_employee.employment_terminated_on,
      :coverage_terminated_on => census_employee.coverage_terminated_on
      })
    enrollments.each do |enr|
      notice.census_employee.enrollments << build_enrollment(enr)
    end
  end

  def build_enrollment(hbx_enrollment)
    plan = PdfTemplates::Plan.new({
      plan_name: hbx_enrollment.plan.name,
      coverage_kind: hbx_enrollment.plan.coverage_kind
      })
    PdfTemplates::Enrollment.new({
      enrolled_count: hbx_enrollment.humanized_dependent_summary,
      plan: plan
    })
  end

end