class ShopNotices::RenewalGroupNotice < ShopNotices::EmployerRenewalNotice

  def deliver
    build
    append_data
    super
  end

  def append_data
    renewing_plan_year = employer_profile.plan_years.where(:aasm_state => "renewing_draft").first
    notice.plan = PdfTemplates::Plan.new({
          :open_enrollment_end_on => renewing_plan_year.open_enrollment_end_on,
          :coverage_start_on => renewing_plan_year.start_on
        })
  end
end