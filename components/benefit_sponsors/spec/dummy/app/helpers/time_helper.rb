module TimeHelper
  def time_remaining_in_words(user_created)
    last_day = user_created.to_date + 95.days
    days = (last_day.to_date - TimeKeeper.date_of_record.to_date).to_i
    pluralize(days, 'day')
  end

  def set_date_min_to_effective_on (enrollment)
    enrollment.effective_on + 1.day
  end

  def set_date_max_to_plan_end_of_year (enrollment)
    year = enrollment.effective_on.year
    if (enrollment.kind == "employer_sponsored")
      final_day = enrollment.effective_on + 1.year - 1.day
    else
      final_day = Date.new(year, 12, 31)
    end
  end

  def set_default_termination_date_value(enrollment)
    TimeKeeper.date_of_record.between?(set_date_min_to_effective_on(enrollment), set_date_max_to_plan_end_of_year(enrollment)) ? TimeKeeper.date_of_record : set_date_max_to_plan_end_of_year(enrollment)
  end

  def sep_optional_date(family, min_or_max, market_kind = nil, effective_date = nil)
    person = family.primary_applicant.person

    return nil unless has_employee_role?(person, market_kind)
    benefit_applications = person.active_employee_roles.map{|ee| ee.census_employee.fetch_benefit_applications_for_date(effective_date)}.flatten.compact
    min_or_max == 'min' ? benefit_applications.map(&:start_on).min : benefit_applications.map(&:end_on).max
  end

  def has_employee_role?(person, market_kind)
    has_dual_roles         = person.has_consumer_role? && person.has_active_employee_role?
    has_only_employee_role = person.has_active_employee_role? && !person.has_consumer_role?

    has_only_employee_role || (has_dual_roles && %w[shop fehb].include?(market_kind))
  end

end
