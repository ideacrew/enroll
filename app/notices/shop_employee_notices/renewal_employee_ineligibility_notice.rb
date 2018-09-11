class ShopEmployeeNotices::RenewalEmployeeIneligibilityNotice < ShopEmployeeNotice
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
    renewing_plan_year = census_employee.employer_profile.plan_years.where(:aasm_state.in => PlanYear::RENEWING + ["renewing_application_ineligible"]).first
    active_plan_year = census_employee.employer_profile.plan_years.where(:aasm_state => "active").first
   plan_year_warnings = []
    renewing_plan_year.enrollment_errors.each do |k, v|
      case k.to_s
      when "enrollment_ratio"
        plan_year_warnings << "At least two-thirds of your eligible employees enrolled in your group health coverage or waive due to having other coverage."
      when "non_business_owner_enrollment_count"
        plan_year_warnings << "One non-owner employee enrolled in health coverage"
      end
    end
     notice.plan_year = PdfTemplates::PlanYear.new({
        :start_on => renewing_plan_year.start_on,
        :open_enrollment_end_on => renewing_plan_year.open_enrollment_end_on,
        :end_on => active_plan_year.end_on,
        :warnings => plan_year_warnings
      })
    hbx = HbxProfile.current_hbx
    bc_period = hbx.benefit_sponsorship.benefit_coverage_periods.detect { |bcp| bcp if (bcp.start_on..bcp.end_on).cover?(TimeKeeper.date_of_record.next_year) }
      notice.enrollment = PdfTemplates::Enrollment.new({
                        :ivl_open_enrollment_start_on => bc_period.open_enrollment_start_on,
                        :ivl_open_enrollment_end_on => bc_period.open_enrollment_end_on
        })
  end
 end 
 