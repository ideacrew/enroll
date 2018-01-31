class ShopEmployeeNotices::EmployeeMatchesEmployerRoosterNotice < ShopEmployeeNotice
  attr_accessor :census_employee

  def deliver
    build
    append_data
    generate_pdf_notice
    employee_appeal_rights_attachment
    attach_envelope
    non_discrimination_attachment
    upload_and_send_secure_message
    send_generic_notice_alert
  end

  def append_data
    notice.employer_full_name = census_employee.employer_profile.staff_roles.first.full_name.titleize
  end
end