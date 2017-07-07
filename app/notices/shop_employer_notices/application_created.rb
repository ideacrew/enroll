class ShopEmployerNotices::WelcomeEmployerNotice < ShopEmployerNotice

  def deliver
    build
    append_data
    generate_pdf_notice
    attach_envelope
    upload_and_send_secure_message
    send_generic_notice_alert
  end
end