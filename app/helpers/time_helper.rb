module TimeHelper
  def time_remaining_in_words(user_created)
    last_day = user_created.to_date + 95.days
    days = (last_day.to_date - TimeKeeper.date_of_record.to_date).to_i
    pluralize(days, 'day')
  end

  def set_date_min_to_effective_on (enrollment)
    enrollment.effective_on + 1.day
  end

  def set_date_min_to_beginning_of_year(enrollment, offset = 0)
    enrollment.effective_on.beginning_of_year + offset.days
  end

  def set_date_max_to_plan_end_of_year (enrollment)
    year = enrollment.effective_on.year
    if (enrollment.kind == "employer_sponsored") || (enrollment.kind == "employer_sponsored_cobra")
      enrollment.sponsored_benefit_package.end_on
    else
      Date.new(year, 12, 31)
    end
  end

  def set_default_termination_date_value(enrollment)
    TimeKeeper.date_of_record.between?(set_date_min_to_effective_on(enrollment), set_date_max_to_plan_end_of_year(enrollment)) ? TimeKeeper.date_of_record : set_date_max_to_plan_end_of_year(enrollment)
  end

  def sep_optional_date(family, min_or_max, market_kind = nil, effective_date = nil)
    person = family.primary_applicant.person
    return if effective_date.nil?
    return nil unless has_employee_role?(person, market_kind)

    benefit_applications = fetch_approved_and_term_bas_for_date(person).flatten.compact
    min_or_max == 'min' ? benefit_applications.map(&:start_on).min : benefit_applications.map(&:end_on).max
  end

  def fetch_approved_and_term_bas_for_date(person)
    plan_years = person.active_employee_roles.map(&:employer_profile).map(&:benefit_applications).map(&:published_or_renewing_published).flatten
    if ::EnrollRegistry.feature_enabled?(:prior_plan_year_shop_sep)
      prior_plan_years = person.active_employee_roles.map(&:employer_profile).map(&:active_benefit_sponsorship).map(&:prior_py_benefit_application)
      plan_years + prior_plan_years
    else
      plan_years
    end
  end

  def has_employee_role?(person, market_kind)
    has_dual_roles         = person.has_consumer_role? && person.has_active_employee_role?
    has_only_employee_role = person.has_active_employee_role? && !person.has_consumer_role?

    has_only_employee_role || (has_dual_roles && %w[shop fehb].include?(market_kind))
  end
end
