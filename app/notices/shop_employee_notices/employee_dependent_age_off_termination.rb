class ShopEmployeeNotices::EmployeeDependentAgeOffTermination < ShopEmployeeNotice

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
    now = TimeKeeper.date_of_record
    hbx = HbxProfile.current_hbx
    # bc_period_current_year = hbx.benefit_sponsorship.benefit_coverage_periods.select { |bcp| bcp.start_on.year == now.year }.first
    # binding.pry
    # unless bc_period = hbx.benefit_sponsorship.benefit_coverage_periods.detect { |bcp| bcp.start_on.year == now.year+1}
    #   bc_period = bc_period_current_year.dup
    #   bc_period_year = now.year + 1
    #   bc_period.start_on = bc_period_current_year.start_on + 1.year
    #   bc_period.open_enrollment_start_on = bc_period_current_year.open_enrollment_start_on + 1.year
    #   bc_period.open_enrollment_end_on = Date.new(2018,1,31)

    bc_period = hbx.benefit_sponsorship.benefit_coverage_periods.detect { |bcp| bcp if (bcp.start_on..bcp.end_on).cover?(TimeKeeper.date_of_record.next_year) }

    census_employee.active_benefit_group_assignment.hbx_enrollment.hbx_enrollment_members.reject(&:is_subscriber).each do |dependent|
      if PlanCostDecorator.benefit_relationship(dependent.primary_relationship).include? "child_under_26"
        dep = dependent.person
        age = now.year - dep.dob.year - ((now.month > dep.dob.month || (now.month == dep.dob.month && now.day >= dep.dob.day)) ? 0 : 1)
        if age >= 25
          # if (now.month == 12 && now.day == 1) || (now.month == dep.dob.month && now.day == 19)
            notice.enrollment = PdfTemplates::Enrollment.new({
              :dependents => dep.full_name,
              :plan_year => bc_period_year,
              :effective_on => bc_period.start_on,
              :ivl_open_enrollment_start_on => bc_period.open_enrollment_start_on,
              :ivl_open_enrollment_end_on => bc_period.open_enrollment_end_on
              })
          # end
        end
      end
    end
  end

end
