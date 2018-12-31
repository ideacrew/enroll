class ShopEmployerNotices::InitialEmployerDenialNotice < ShopEmployerNotice

  def deliver
    build
    append_data
    generate_pdf_notice
    non_discrimination_attachment
    attach_envelope
    upload_and_send_secure_message
    send_generic_notice_alert
    send_generic_notice_alert_to_broker_and_ga
  end

  def append_data
    plan_year = employer_profile.benefit_applications.where(aasm_state: 'pending').last
    policy = eligibility_policy.business_policies_for(plan_year, :submit_benefit_application)
    unless policy.is_satisfied?(plan_year)
      plan_year_warnings = []
      policy.fail_results.each do |k, v|
        case k.to_s
        when "benefit_application_fte_count"
          plan_year_warnings << "Full Time Equivalent must be 1-50"
        when "employer_primary_office_location"
          plan_year_warnings << "primary business address not located in the District of Columbia"
        end
      end
      notice.plan_year = PdfTemplates::PlanYear.new({
            :warnings => plan_year_warnings,
          })
    end
  end

  def eligibility_policy
    return @eligibility_policy if defined? @eligibility_policy
    @eligibility_policy = BenefitSponsors::BenefitApplications::AcaShopApplicationEligibilityPolicy.new
  end
end
