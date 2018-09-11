Organization.where({
  :'employer_profile.plan_years' =>
  { :$elemMatch => {
    :start_on => TimeKeeper.date_of_record.next_month.next_month.beginning_of_month,
    :aasm_state => 'renewing_draft'
  }}
}).each do |org|
  py = org.employer_profile.renewing_plan_year
  if py.may_force_publish? && py.is_application_valid?
    org.employer_profile.renewing_plan_year.force_publish!
  else
    puts "Organization:#{org.fein} plan_year_errors: #{py.errors} & application_warnings: #{py.application_eligibility_warnings}"
  end 
end