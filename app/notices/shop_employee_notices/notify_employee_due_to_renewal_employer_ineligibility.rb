class ShopEmployeeNotices::NotifyEmployeeDueToRenewalEmployerIneligibility < ShopEmployeeNotice

  attr_accessor :census_employee

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
    active_plan_year = census_employee.employer_profile.plan_years.where(:aasm_state => "active").first
    notice.plan_year = PdfTemplates::PlanYear.new({
                      :end_on => active_plan_year.end_on
      })
  end

end