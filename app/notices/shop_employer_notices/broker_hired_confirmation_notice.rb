class ShopEmployerNotices::BrokerHiredConfirmationNotice < ShopEmployerNotice

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
  end	


end