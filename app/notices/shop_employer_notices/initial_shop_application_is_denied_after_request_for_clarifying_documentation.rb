class ShopEmployerNotices::InitialShopApplicationIsDeniedAfterRequestForClarifyingDocumentation < ShopEmployerNotice
  def deliver
    build
    generate_pdf_notice
    employer_appeal_rights_attachment
    attach_envelope
    non_discrimination_attachment
    upload_and_send_secure_message
    send_generic_notice_alert
    send_generic_notice_alert_to_broker
  end

end