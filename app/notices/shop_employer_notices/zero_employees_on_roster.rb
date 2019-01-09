class ShopEmployerNotices::ZeroEmployeesOnRoster < ShopEmployerNotice

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
    plan_year = employer_profile.published_benefit_application
    notice.plan_year = PdfTemplates::PlanYear.new({
          :open_enrollment_end_on => plan_year.open_enrollment_end_on,
        })
    #binder payment deadline
    scheduler = BenefitSponsors::BenefitApplications::BenefitApplicationSchedular.new
    notice.plan_year.binder_payment_due_date = scheduler.calculate_open_enrollment_date(plan_year.start_on)[:binder_payment_due_date]
  end
end
