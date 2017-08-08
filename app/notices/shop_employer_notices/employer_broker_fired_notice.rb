class ShopEmployerNotices::EmployerBrokerFiredNotice < ShopEmployerNotice

  attr_accessor :employer_profile

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

  end

end
