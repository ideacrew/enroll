class ShopEmployerNotices::RenewalEmployerReminderToPublishPlanyear < ShopEmployerNotice

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
    plan_year = employer_profile.benefit_applications.where(:predecessor_id => {:$exists => true}, :aasm_state => "draft").first
    notice.plan_year = PdfTemplates::PlanYear.new({
          :start_on => plan_year.start_on,
        })
  end
end