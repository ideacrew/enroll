class ShopEmployerNotices::EmployerRenewalEligibilityDenialNotice < ShopEmployerNotice

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
    plan_year = employer_profile.plan_years.where(:aasm_state.in => PlanYear::RENEWING - PlanYear::RENEWING_PUBLISHED_STATE).first
    notice.plan_year = PdfTemplates::PlanYear.new({
          :end_on => plan_year.end_on
        })
  end
end