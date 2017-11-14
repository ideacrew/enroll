class ShopEmployerNotices::EmployerRenewalDentalCarriersExitingNotice < ShopEmployerNotice

  def deliver
    build
    append_data
    generate_pdf_notice
    shop_dchl_rights_attachment
    non_discrimination_attachment
    attach_envelope
    upload_and_send_secure_message
    send_generic_notice_alert
  end

  def append_data
    
  end
  
end