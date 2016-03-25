Given(/I set the eligibility rule to (.*)/) do |rule|
  offsets = {
    'first of month following or coinciding with date of hire' => 0,
    'first of month following 30 days' => 30,
    'first of month following 60 days' => 60
  }

  employer_profile = EmployerProfile.find_by_fein(people['Soren White'][:fein])
  employer_profile.plan_years.published.first.benefit_groups.first.update_attributes({
    'effective_on_kind' => 'first_of_month',
    'effective_on_offset' => offsets[rule]
    })
end

Given(/the Employee has current hire on date/) do 
  CensusEmployee.where(:first_name => /Soren/i, :last_name => /White/i).first.update_attributes(:hired_on => Date.today)
end

def expected_effective_on
  employee = Person.where(:first_name => /Soren/i, :last_name => /White/i).first
  employee.active_employee_roles.first.coverage_effective_on
end

Then(/Employee tries to purchase another plan/) do
  step "When Employee clicks \"Shop for Plans\" on my account page"
  step "When Employee clicks shop for new plan on the group selection page"
  step "Then Employee should see the list of plans"
  step "And I should not see any plan which premium is 0"
  step "When Employee selects a plan on the plan shopping page" 
  step "Then Employee should see coverage summary page with employer name and plan details"
  step "When Employee clicks on Confirm button on the coverage summary page"
  step "Then Employee should see receipt page with employer name and plan details"
  step "When Employee clicks on Continue button on receipt page"
  # step "Then Employee should see the \"my account\" page"
  step "Then Employee should see my account page"
end

When(/When Employee clicks \"Shop for Plans\" on my account page/) do
  find('.interaction-click-control-shop-for-plans').click
end

When(/When Employee clicks shop for new plan on the group selection page/) do 
  find('.interaction-click-control-shop-for-new-plan').click
end

Then(/Then Employee should see (.*) page with employer name and plan details/) do |page|
  employer_profile = EmployerProfile.find_by_fein(people['Soren White'][:fein])
  find('p', text: employer_profile.legal_name)
  find('.coverage_effective_date', text: expected_effective_on.strftime("%m/%d/%Y"))
end

When(/When Employee clicks on Continue button on receipt page/) do 
  find('.interaction-click-control-continue').click
end

When(/Then Employee should see my account page/) do
end

