class ShopEmployeeNotices::EmployeeTerminatingCoverage < ShopEmployeeNotice
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
 		enrollment = census_employee.active_benefit_group_assignment.hbx_enrollments.first
    plan = enrollment.plan
    notice.plan = PdfTemplates::Plan.new({
                                             :plan_name => plan.try(:name)
                                         })
 		terminated_enrollment = census_employee.active_benefit_group_assignment.hbx_enrollment
    notice.enrollment = PdfTemplates::Enrollment.new({
      :terminated_on => terminated_enrollment.set_coverage_termination_date,
      :enrolled_count => terminated_enrollment.humanized_dependent_summary
      })
 	end	

end
