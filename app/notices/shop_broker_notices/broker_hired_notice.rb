class ShopBrokerNotices::BrokerHiredNotice < ShopBrokerNotice

  def deliver
    build
    generate_pdf_notice
    attach_envelope
    non_discrimination_attachment
    upload_and_send_secure_message
    send_generic_notice_alert
  end
end
