class ShopEmployerNotices::InitialEmployerDenialNotice < ShopEmployerNotice

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
    plan_year = employer_profile.plan_years.first
    plan_year_warnings = []
    if plan_year
      plan_year.application_eligibility_warnings.each do |k, _|
        case k.to_s
        when "fte_count"
          plan_year_warnings << "Full Time Equivalent must be 1-50"
        when "primary_office_location"
          plan_year_warnings << "primary business address not located in #{Settings.aca.state_name}"
        end
      end      
    else
      plan_year_warnings << "primary business address not located in #{Settings.aca.state_name}"
    end
    
    notice.plan_year = PdfTemplates::PlanYear.new({
          :warnings => plan_year_warnings,
        })
  end

end