class ShopEmployeeNotices::EePlanConfirmationSepNewHire < ShopEmployeeNotice

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
    sep = census_employee.employee_role.person.primary_family.special_enrollment_periods.order_by(:"created_at".desc)[0]
    new_hire = census_employee.employee_role.person.primary_family.households.first.hbx_enrollments.order_by(:"created_at".desc)[0]
    effective_on = sep.present? ? sep.effective_on : new_hire.effective_on
    build_plan = new_hire.build_plan_premium
    # notice.sep = PdfTemplates::SpecialEnrollmentPeriod.new({
    #   :effective_on => effective_on
    #   })
    notice.enrollment = PdfTemplates::Enrollment.new({
                                                         :effective_on => effective_on,
                                                         :plan => {:plan_name => new_hire.plan.name},
                                                         :employee_cost => build_plan.total_employee_cost,
                                                         :employer_cost => build_plan.total_employer_contribution
                                                     })
    notice.employer_name = census_employee.employer_profile.legal_name
  end

end