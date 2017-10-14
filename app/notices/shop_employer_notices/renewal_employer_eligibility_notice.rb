class ShopEmployerNotices::RenewalEmployerEligibilityNotice < ShopEmployerNotice

  attr_accessor :employer_profile

  def deliver
    build
    generate_pdf_notice
    shop_dchl_rights_attachment
    non_discrimination_attachment
    attach_envelope
    upload_and_send_secure_message
    send_generic_notice_alert
    send_generic_notice_alert_to_broker_and_ga
  end

end 
