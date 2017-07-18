module FinancialAssistanceHelper
  def to_est datetime
    datetime.in_time_zone("Eastern Time (US & Canada)") if datetime.present?
  end

  def total_aptc_sum application_id
    application = FinancialAssistance::Application.find(application_id)
    sum = 0.0
    application.tax_households.each do |thh|
      sum = sum + thh.preferred_eligibility_determination.max_aptc
    end
    return sum
  end

  def eligible_applicants application_id, eligibility_flag
    application = FinancialAssistance::Application.find(application_id)
    application.applicants.where(eligibility_flag => true).map(&:person).map(&:full_name).map(&:titleize)
  end

  def applicant_age applicant
    now = Time.now.utc.to_date
    dob = applicant.family_member.person.dob
    age = now.year - dob.year - ((now.month > dob.month || (now.month == dob.month && now.day >= dob.day)) ? 0 : 1)
  end

  def activer_for(target)
    p controller_name
    p action_name
    p target
    if controller_name == 'applicants'
      if action_name == 'step'
        if target == 'income_and_coverage'
          'activer'
        else
          ''
        end
      else
        ''
      end
    elsif controller_name == 'incomes'
      if ['income_and_coverage', 'tax_info'].include?(target)
        'activer'
      else
        ''
      end
    elsif controller_name == "deductions"
      if ['income_and_coverage', 'tax_info', 'income'].include?(target)
        'activer'
      else
        ''
      end
    elsif controller_name == "benefits"
      if ['income_and_coverage', 'tax_info', 'income', 'income_adjustments'].include?(target)
        'activer'
      else
        ''
      end
    end
  end
end
