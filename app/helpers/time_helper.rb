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

  def sep_optional_date family, min_or_max
    person = family.primary_applicant.person
    if person.has_consumer_role?
      min_or_max == 'min' ? TimeKeeper.date_of_record.beginning_of_year : TimeKeeper.date_of_record.end_of_year
    else
      active_plan_years = person.employee_roles.map(&:employer_profile).map(&:plan_years).map(&:published_or_renewing_published).flatten
      min_or_max == 'min' ? active_plan_years.map(&:start_on).min : active_plan_years.map(&:end_on).max
    end
  end

end
