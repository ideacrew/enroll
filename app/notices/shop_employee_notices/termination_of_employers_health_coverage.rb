class ShopEmployeeNotices::TerminationOfEmployersHealthCoverage < ShopEmployeeNotice

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
    active_plan_year = census_employee.employer_profile.plan_years.where(:aasm_state.in => PlanYear::INITIAL_ELIGIBLE_STATE).first
    notice.plan_year = PdfTemplates::PlanYear.new({
                      :start_on => active_plan_year.start_on
      })

    hbx = HbxProfile.current_hbx
    binding.pry
    bc_period = hbx.benefit_sponsorship.benefit_coverage_periods.detect { |bcp| bcp if (bcp.start_on..bcp.end_on).cover?(TimeKeeper.date_of_record.next_year) }
    notice.enrollment = PdfTemplates::Enrollment.new({
              :ivl_open_enrollment_start_on => bc_period.open_enrollment_start_on,
              :ivl_open_enrollment_end_on => bc_period.open_enrollment_end_on
              })
  end
end
