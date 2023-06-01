module ApplicationHelper
  def format_date(date_value)
    date_value.strftime("%m/%d/%Y") if date_value.respond_to?(:strftime)
  end

  def benefit_application_summarized_state(benefit_application)
    return if benefit_application.nil?

    aasm_map = {
      :draft => :draft,
      :enrollment_open => :enrolling,
      :enrollment_eligible => :enrolled,
      :binder_paid => :enrolled,
      :approved => :published,
      :pending => :publish_pending
    }

    renewing = benefit_application.predecessor_id.present? && benefit_application.aasm_state != :active ? "Renewing" : ""
    summary_text = aasm_map[benefit_application.aasm_state] || benefit_application.aasm_state
    summary_text = "#{renewing} #{summary_text.to_s.humanize.titleize}"
    summary_text.strip
  end

  def product_rates_available?(benefit_sponsorship, date = nil)
    date = Date.strptime(date.strftime("%m/%d/%Y"), '%m/%d/%Y') if date.present?
    return false if benefit_sponsorship.present? && benefit_sponsorship.active_benefit_application.present?

    date ||= BenefitSponsors::BenefitApplications::BenefitApplicationSchedular.new.calculate_start_on_dates[0]
    benefit_sponsorship.applicant? && BenefitMarkets::Forms::ProductForm.for_new(date).fetch_results.is_late_rate
  end

  def show_oop_pdf_link(aasm_state)
    return false if aasm_state.blank?

    BenefitSponsors::BenefitApplications::BenefitApplication::SUBMITTED_STATES.include?(aasm_state.to_sym)
  end

  def env_bucket_name(bucket_name)
    aws_env = ENV['AWS_ENV'] || "qa"
    "dchbx-enroll-#{bucket_name}-#{aws_env}"
  end

  def link_to_with_noopener_noreferrer(name, path, options = {})
    link_to(name, path, options.merge(rel: 'noopener noreferrer'))
  end
end
