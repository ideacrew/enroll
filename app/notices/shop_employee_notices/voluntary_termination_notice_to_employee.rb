class ShopEmployeeNotices::VoluntaryTerminationNoticeToEmployee < ShopEmployeeNotice

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
    plan_year = census_employee.employer_profile.plan_years.where(:aasm_state.in => ["terminated", "termination_pending"]).sort_by(&:updated_at).last
    end_on_plus_60_days = plan_year.end_on + 60.days
    notice.plan_year = PdfTemplates::PlanYear.new({
                                                      :end_on => plan_year.end_on,
                                                      :end_on_plus_60_days => end_on_plus_60_days
                                                  })
  end
end