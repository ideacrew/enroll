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
    shop_enrollments = census_employee.employee_role.person.primary_family.active_household.hbx_enrollments.shop_market
    
    waived_enrollment = shop_enrollments.where(:aasm_state => "inactive").desc(:created_at).first

    covered_dependents_count = waived_enrollment.hbx_enrollment_members.reject{ |mem| mem.is_subscriber}.count
    notice.enrollment = PdfTemplates::Enrollment.new({
      :enrollees_count => covered_dependents_count,
      :effective_on => waived_enrollment.effective_on
    })

    term_enrollment = shop_enrollments.where(:aasm_state.in => ["coverage_terminated", "coverage_termination_pending"]).desc(:created_at).first
    
    if term_enrollment.present?
      covered_dependents_count = term_enrollment.hbx_enrollment_members.reject{ |mem| mem.is_subscriber}.count
      notice.term_enrollment = PdfTemplates::Enrollment.new({
        :enrollees_count => covered_dependents_count,
        :terminated_on => term_enrollment.terminated_on,
        :effective_on => term_enrollment.effective_on
      })
      notice.plan = PdfTemplates::Plan.new({
        :plan_name => term_enrollment.plan.name
      })
    end
  end
end
