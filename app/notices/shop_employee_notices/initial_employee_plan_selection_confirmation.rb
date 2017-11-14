class ShopEmployeeNotices::InitialEmployeePlanSelectionConfirmation < ShopEmployeeNotice

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
    plan_year = census_employee.employer_profile.active_plan_year
    notice.plan_year = PdfTemplates::PlanYear.new({
      :start_on => plan_year.start_on
      })

    enrollment = census_employee.active_benefit_group_assignment.hbx_enrollments.first
    notice.enrollment = PdfTemplates::Enrollment.new({ 
      responsible_amount: enrollment.total_employer_contribution,
      employee_cost: enrollment.total_employee_cost,
      })

    plan = enrollment.plan
    notice.plan = PdfTemplates::Plan.new({
      :plan_name => plan.name
    })

  end
end