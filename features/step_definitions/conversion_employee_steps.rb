Given(/Conversion Employer for (.*) exists with active and renewing plan year/) do |named_person|
  person = people[named_person]
  organization = FactoryGirl.create :organization, legal_name: person[:legal_name], dba: person[:dba], fein: person[:fein]
  employer_profile = FactoryGirl.create :employer_profile, organization: organization, profile_source:'conversion', registered_on: TimeKeeper.date_of_record
  owner = FactoryGirl.create :census_employee, :owner, employer_profile: employer_profile
  employee = FactoryGirl.create :census_employee, employer_profile: employer_profile,
    first_name: person[:first_name],
    last_name: person[:last_name],
    ssn: person[:ssn],
    dob: person[:dob_date]

  open_enrollment_start_on = TimeKeeper.date_of_record.end_of_month + 1.day
  open_enrollment_end_on = open_enrollment_start_on.next_month + 12.days
  start_on = open_enrollment_start_on + 2.months
  end_on = start_on + 1.year - 1.day

  plan_year = FactoryGirl.create :plan_year, employer_profile: employer_profile, start_on: start_on - 1.year, end_on: end_on - 1.year, open_enrollment_start_on: open_enrollment_start_on - 1.year, open_enrollment_end_on: open_enrollment_end_on - 1.year - 3.days, fte_count: 2, aasm_state: :published
  benefit_group = FactoryGirl.create :benefit_group, plan_year: plan_year
  employee.add_benefit_group_assignment benefit_group, benefit_group.start_on

  plan_year = FactoryGirl.create :plan_year, employer_profile: employer_profile, start_on: start_on, end_on: end_on, open_enrollment_start_on: open_enrollment_start_on, open_enrollment_end_on: open_enrollment_end_on, fte_count: 2, aasm_state: :renewing_draft
  benefit_group = FactoryGirl.create :benefit_group, plan_year: plan_year
  employee.add_renew_benefit_group_assignment benefit_group

  FactoryGirl.create(:qualifying_life_event_kind, market_kind: "shop")
  Caches::PlanDetails.load_record_cache!
end

Then(/Employee (.*) should see renewing plan year start date as earliest effective date/) do |named_person|
  person = people[named_person]
  employer_profile = EmployerProfile.find_by_fein(person[:fein])
  find('label', text: "Enroll as an employee of #{employer_profile.legal_name} with coverage starting #{employer_profile.renewing_plan_year.start_on.strftime("%m/%d/%Y")}.")
end

And(/(.*) already matched and logged into employee portal/) do |named_person|
  person = people[named_person]
  employer_profile = EmployerProfile.find_by_fein(person[:fein])
  ce = employer_profile.census_employees.where(:first_name => /#{person[:first_name]}/i, :last_name => /#{person[:last_name]}/i).first
  person_record = FactoryGirl.create(:person_with_employee_role, first_name: person[:first_name], last_name: person[:last_name], ssn: person[:ssn], dob: person[:dob_date], census_employee_id: ce.id, employer_profile_id: employer_profile.id, hired_on: ce.hired_on)
  FactoryGirl.create :family, :with_primary_family_member, person: person_record
  user = FactoryGirl.create(:user, person: person_record, email: person[:email], password: person[:password], password_confirmation: person[:password])
  login_as user
  visit "/families/home"
end

Then(/Employee should see \"employer-sponsored benefits not found\" error message/) do
  screenshot("new_hire_not_yet_eligible_exception")
  find('.alert', text: "Unable to find employer-sponsored benefits for enrollment year")
  visit '/families/home'
end

And(/Employer for (.*) published renewing plan year/) do |named_person|
  person = people[named_person]
  employer_profile = EmployerProfile.find_by_fein(person[:fein])
  employer_profile.renewing_plan_year.update_attributes(:aasm_state => 'renewing_published')
end

When(/Employee clicks on New Hire Badge/) do
  find('#shop_for_employer_sponsored_coverage').click
end

Then(/(.*) should see \"open enrollment not yet started\" error message/) do |named_person|
  person = people[named_person]
  employer_profile = EmployerProfile.find_by_fein(person[:fein])
  find('.alert', text: "Open enrollment for your employer-sponsored benefits not yet started. Please return on #{employer_profile.renewing_plan_year.open_enrollment_start_on.strftime("%m/%d/%Y")} to enroll for coverage.")
  visit '/families/home'
end