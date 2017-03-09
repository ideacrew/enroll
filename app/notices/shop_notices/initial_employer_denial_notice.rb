class ShopNotices::InitialEmployerDenialNotice < ShopNotice

  def deliver
    build
    append_data
    generate_pdf_notice
    attach_envelope
    upload_and_send_secure_message
    send_generic_notice_alert
  end

  def append_data
    plan_year = employer_profile.plan_years.first
    plan_year_warnings = []
    plan_year.application_eligibility_warnings.each do |k, v|
      case k.to_s
      when "fte_count"
        plan_year_warnings << "Full Time Employees count not in 1-50(can't be 0)"
      when "primary_office_location"
        plan_year_warnings << "address not in DC"
      end
    end
    notice.plan_year = PdfTemplates::PlanYear.new({
          :warnings => plan_year_warnings,
        })
  end

end