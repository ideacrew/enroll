class ShopEmployerNotices::InitialEmployerFirstInvoiceAvailable < ShopEmployerNotice

  def deliver
    build
    append_data
    generate_pdf_notice
    non_discrimination_attachment
    attach_envelope
    upload_and_send_secure_message
    send_generic_notice_alert
    send_generic_notice_alert_to_broker_and_ga
  end

  def append_data
    aasm_states = BenefitSponsors::BenefitApplications::BenefitApplication::APPROVED_STATES
    plan_year = employer_profile.plan_years.where(:aasm_state.in => aasm_states).first
    notice.plan_year = PdfTemplates::PlanYear.new({
          :start_on => plan_year.start_on,
        })

    scheduler = BenefitSponsors::BenefitApplications::BenefitApplicationSchedular.new
    notice.plan_year.binder_payment_due_date = scheduler.calculate_open_enrollment_date(plan_year.start_on)[:binder_payment_due_date]
  end
end
