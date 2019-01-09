class ShopEmployerNotices::RenewalEmployerIneligibilityNotice < ShopEmployerNotice

  def deliver
    build
    append_data
    generate_pdf_notice
    shop_dchl_rights_attachment
    non_discrimination_attachment
    attach_envelope
    upload_and_send_secure_message
    send_generic_notice_alert
    send_generic_notice_alert_to_broker_and_ga
  end

  def append_data
    renewing_plan_year = employer_profile.benefit_applications.where(:aasm_state => "enrollment_ineligible").order_by(:"created_at".desc).first
    active_plan_year = employer_profile.benefit_applications.where(:start_on => renewing_plan_year.start_on.prev_year.to_date, :aasm_state.in => ["active", "terminated", "expired"]).first
    policy = enrollment_policy.business_policies_for(renewing_plan_year, :end_open_enrollment)
    unless policy.is_satisfied?(renewing_plan_year)
      plan_year_warnings = []
      policy.fail_results.each do |k, v|
        case k.to_s
        when "minimum_participation_rule"
          plan_year_warnings << "At least two-thirds of your eligible employees enrolled in your group health coverage or waive due to having other coverage."
        when "non_business_owner_enrollment_count"
          plan_year_warnings << "One non-owner employee enrolled in health coverage"
        end
      end

      notice.plan_year = PdfTemplates::PlanYear.new({
          :start_on => renewing_plan_year.start_on,
          :open_enrollment_end_on => renewing_plan_year.open_enrollment_end_on,
          :end_on => active_plan_year.end_on,
          :warnings => plan_year_warnings
        })
    end
  end

  def enrollment_policy
    return @enrollment_policy if defined? @enrollment_policy
    @enrollment_policy = BenefitSponsors::BenefitApplications::AcaShopEnrollmentEligibilityPolicy.new
  end
end
