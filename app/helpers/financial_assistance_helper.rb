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

  def checked_value_for_radio model, attribute, bool
    if bool == false
      val = model.send(attribute)
      val || val.blank? ? false : true
    end
  end
end
