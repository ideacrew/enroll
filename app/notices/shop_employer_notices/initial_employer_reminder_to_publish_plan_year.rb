class ShopEmployerNotices::InitialEmployerReminderToPublishPlanYear < ShopEmployerNotice

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
    notice.aasm_state ||= "draft"
    plan_year = employer_profile.plan_years.where(:aasm_state => notice.aasm_state).first
    notice.plan_year = PdfTemplates::PlanYear.new({
          :start_on => plan_year.start_on,
        })
    notice.plan_year.binder_payment_due_date = PlanYear.calculate_open_enrollment_date(plan_year.start_on)[:binder_payment_due_date]
  end
end