class ShopEmployeeNotices::EmployeeMatchesEmployerRoosterNotice < ShopEmployeeNotice
  attr_accessor :census_employee

  def deliver
    build
    generate_pdf_notice
    employee_appeal_rights_attachment
    attach_envelope
    non_discrimination_attachment
    upload_and_send_secure_message
    send_generic_notice_alert
  end
end