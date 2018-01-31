class ShopEmployeeNotices::EmployeeWaiverConfirmNotice < ShopEmployeeNotice
  attr_accessor :census_employee

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
    notice.enrollment = PdfTemplates::Enrollment.new({
                      :waived_on => census_employee.active_benefit_group_assignment.hbx_enrollments.first.updated_at
      })
  end
end