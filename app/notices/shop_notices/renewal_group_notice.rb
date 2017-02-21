class ShopNotices::RenewalGroupNotice < ShopNotice

  def deliver
    build
    generate_pdf_notice
    append_data
    upload_and_send_secure_message
    send_generic_notice_alert
  end

  def append_data
    renewing_plan_year = employer_profile.plan_years.where(:aasm_state => "renewing_draft").first
    notice.plan_year = PdfTemplates::PlanYear.new({
          :open_enrollment_end_on => renewing_plan_year.open_enrollment_end_on,
          :start_on => renewing_plan_year.start_on,
        })
  end

end