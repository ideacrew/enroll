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

And(/Employer for (.*) is under open enrollment/) do |named_person|
  person = people[named_person]
  employer_profile = EmployerProfile.find_by_fein(person[:fein])

  open_enrollment_start_on = TimeKeeper.date_of_record
  open_enrollment_end_on = open_enrollment_start_on.end_of_month + 12.days
  start_on = open_enrollment_start_on.end_of_month + 1.day + 1.month
  end_on = start_on + 1.year - 1.day
  employer_profile.renewing_plan_year.update_attributes(:aasm_state => 'renewing_enrolling', :open_enrollment_start_on => open_enrollment_start_on,
    :open_enrollment_end_on => open_enrollment_end_on, :start_on => start_on, :end_on => end_on)
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

Then(/(.*) should get plan year start date as coverage effective date/) do |named_person|
  person = people[named_person]
  employer_profile = EmployerProfile.find_by_fein(person[:fein])
  find('.coverage_effective_date', text: employer_profile.renewing_plan_year.start_on.strftime("%m/%d/%Y"))
end

When(/(.+) should see coverage summary page with renewing plan year start date as effective date/) do |named_person|
  step "#{named_person} should get plan year start date as coverage effective date"
  find('.interaction-click-control-confirm').click
end

Then(/(.*) should see the receipt page with renewing plan year start date as effective date/) do |named_person|
  expect(page).to have_content('Enrollment Submitted')
  step "#{named_person} should get plan year start date as coverage effective date"

  if page.has_link?('CONTINUE')
    click_link "CONTINUE"
  else
    click_link "GO TO MY ACCOUNT"
  end
end

When(/Employee click the "(.*?)" in qle carousel/) do |qle_event|
  click_link "#{qle_event}"
end

When(/Employee select a past qle date/) do
  expect(page).to have_content "Married"
  screenshot("past_qle_date")
  fill_in "qle_date", :with => (TimeKeeper.date_of_record - 5.days).strftime("%m/%d/%Y")
  within '#qle-date-chose' do
    click_link "CONTINUE"
  end
end

Then(/Employee should see confirmation and clicks continue/) do
  expect(page).to have_content "Based on the information you entered, you may be eligible to enroll now but there is limited time"
  screenshot("valid_qle")
  click_button "Continue"
end

Then(/Employee should see family members page and clicks continue/) do
  expect(page).to have_content "Household Info: Family Members"
  within '#dependent_buttons' do
    click_link "Continue"
  end
end
