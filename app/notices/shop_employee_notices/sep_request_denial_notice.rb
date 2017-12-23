class ShopEmployeeNotices::SepRequestDenialNotice < ShopEmployeeNotice

  attr_accessor :census_employee

  def initialize(census_employee, args = {})
    @qle_reported_date = args[:options][:qle_reported_date]
    @qle_title = args[:options][:qle_title]
    super(census_employee, args)
  end

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
    notice.sep = PdfTemplates::SpecialEnrollmentPeriod.new({:start_on => @qle_reported_date,
                                                            :end_on => @qle_reported_date + 30.day,
                                                            :title => @qle_title
                                                           })

    active_plan_year = census_employee.employer_profile.plan_years.where(:aasm_state.in => PlanYear::PUBLISHED).first
    renewing_plan_year = census_employee.employer_profile.renewing_published_plan_year

    if renewing_plan_year.present?
      future_py_start_on,open_enrollment_end_date_py = if renewing_plan_year.open_enrollment_contains?(TimeKeeper.date_of_record)
                                                         [renewing_plan_year.start_on, active_plan_year]
                                                       else
                                                         [renewing_plan_year.end_on + 1, renewing_plan_year]
                                                       end
    end

    open_enrollment_py = open_enrollment_end_date_py.present? ? open_enrollment_end_date_py : active_plan_year
    upcoming_plan_year_start_on = future_py_start_on.present? ? future_py_start_on : active_plan_year.end_on + 1

    notice.plan_year = PdfTemplates::PlanYear.new({
      :open_enrollment_end_on => open_enrollment_py.open_enrollment_end_on,
      :open_enrollment_start_on => open_enrollment_py.start_on,
      :start_on => upcoming_plan_year_start_on
      })

    hbx = HbxProfile.current_hbx
    bc_period = hbx.benefit_sponsorship.benefit_coverage_periods.detect { |bcp| bcp if (bcp.start_on..bcp.end_on).cover?(TimeKeeper.date_of_record.next_year) }
    notice.enrollment = PdfTemplates::Enrollment.new({
              :effective_on => bc_period.start_on,
              :plan_year => bc_period.start_on.year,
              :ivl_open_enrollment_start_on => bc_period.open_enrollment_start_on,
              :ivl_open_enrollment_end_on => bc_period.open_enrollment_end_on
              })
  end
end
