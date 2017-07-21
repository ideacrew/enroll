class ShopEmployeeNotices::EmployeeDependentAgeOffTermination < ShopEmployeeNotice

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
    now = TimeKeeper.date_of_record
    hbx = HbxProfile.current_hbx
    bc_period = hbx.benefit_sponsorship.benefit_coverage_periods.detect { |bcp| bcp if (bcp.start_on..bcp.end_on).cover?(now.next_year) }
    names = []
    if bc_period.present?
      if census_employee.active_benefit_group_assignment.present? && census_employee.active_benefit_group_assignment.hbx_enrollment.present? && census_employee.active_benefit_group_assignment.hbx_enrollment.hbx_enrollment_members.count >= 1
        census_employee.active_benefit_group_assignment.hbx_enrollment.hbx_enrollment_members.reject(&:is_subscriber).each do |dependent|
          if PlanCostDecorator.benefit_relationship(dependent.primary_relationship).include? "child_under_26"
            dep = dependent.person
            age = now.year - dep.dob.year - ((now.month > dep.dob.month || (now.month == dep.dob.month && now.day >= dep.dob.day)) ? 0 : 1)
            if age >= 25
              if (now.month == 12 && now.day == 1) || (now.month == dep.dob.month && now.day == 1)
                names << dep.full_name
                notice.enrollment = PdfTemplates::Enrollment.new({
                  :dependents => names,
                  :plan_year => bc_period.start_on.year,
                  :effective_on => bc_period.start_on,
                  :ivl_open_enrollment_start_on => bc_period.open_enrollment_start_on,
                  :ivl_open_enrollment_end_on => bc_period.open_enrollment_end_on
                  })
              end
            end
          end
        end
      end
    end
  end
end
