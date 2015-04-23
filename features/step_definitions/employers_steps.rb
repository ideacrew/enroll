Given(/^I haven't signed up as an HBX user$/) do
end

When(/^I visit the Employer portal$/) do
  @browser.goto("http://localhost:3000/")
  Watir::Wait.until(30) { @browser.a(text: "Employer Portal").present? }
  sleep(1)
  @browser.a(text: "Employer Portal").click
  Watir::Wait.until(30) { @browser.a(text: "Create account").present? }
  sleep(1)
  @browser.a(text: "Create account").click
end

And(/^I sign up with valid user data$/) do
  Watir::Wait.until(30) { @browser.text_field(name: "user[password_confirmation]").present? }
  @browser.text_field(name: "user[email]").set("trey.evans#{rand(100)}@dc.gov")
  @browser.text_field(name: "user[password]").set("12345678")
  @browser.text_field(name: "user[password_confirmation]").set("12345678")
  @browser.input(value: "Create account").click
end

Then(/^I should see a successful sign up message$/) do
  Watir::Wait.until(30) { @browser.element(text: /Welcome! You have signed up successfully./).present? }
  expect(@browser.element(text: /Welcome! You have signed up successfully./).visible?).to be_truthy
end

And(/^I should see an initial form to enter information about my Employer and myself$/) do
  expect(@browser.button(name: "commit").visible?).to be_truthy
  expect(@browser.button.value == "Create").to be_truthy
  @browser.button(name: "commit").click
end

Given(/^I have signed up previously through consumer, broker agency or previous visit to the Employer portal with email (.+)$/) do |email|
end

When(/^I visit the Employer portal to sign in$/) do
  @browser.goto("http://localhost:3000/")
  Watir::Wait.until(30) { @browser.a(text: "Employer Portal").present? }
  sleep(1)
  @browser.a(text: "Employer Portal").click
end

And(/^I sign in with valid user data with email (.+) and password (.+)$/) do |email, password|
  Watir::Wait.until(30) { @browser.input(value: "Sign in").present? }
  user = FactoryGirl.create(:user)
  FactoryGirl.create(:plan)
  @browser.text_field(name: "user[email]").set(user.email)
  @browser.text_field(name: "user[password]").set(user.password)
  @browser.input(value: "Sign in").click
end

Then(/^I should see a successful sign in message$/) do
  Watir::Wait.until(30) { @browser.text.include?("Signed in successfully.") }
  expect(@browser.text.include?("Signed in successfully.")).to be_truthy
end

And(/^I should see an initial form with a fieldset for Employer information, including: legal name, DBA, fein, entity_kind, broker agency, URL, address, and phone$/) do
  Watir::Wait.until(30) { @browser.text_field(name: "organization[employer_profile_attributes][fein]").present?}
  sleep(1)
  # Employer info
  @browser.text_field(name: "organization[employer_profile_attributes][fein]").set("678123089")
  @browser.text_field(name: "organization[employer_profile_attributes][dba]").set("test")
  @browser.text_field(name: "organization[employer_profile_attributes][legal_name]").set("True First Inc")
  @browser.select_list(name: "organization[employer_profile_attributes][entity_kind]").select_value("s_corporation")
  #Plan Year
  @browser.text_field(name: "organization[employer_profile_attributes][plan_years_attributes][0][start_on]").set("01/01/2015")
  @browser.text_field(name: "organization[employer_profile_attributes][plan_years_attributes][0][end_on]").set("12/31/2015")
  @browser.text_field(name: "organization[employer_profile_attributes][plan_years_attributes][0][open_enrollment_start_on]").set("11/01/2014")
  @browser.text_field(name: "organization[employer_profile_attributes][plan_years_attributes][0][open_enrollment_end_on]").set("11/30/2014")
  @browser.text_field(name: "organization[employer_profile_attributes][plan_years_attributes][0][fte_count]").set("35")
  @browser.text_field(name: "organization[employer_profile_attributes][plan_years_attributes][0][pte_count]").set("15")
  @browser.text_field(name: "organization[employer_profile_attributes][plan_years_attributes][0][msp_count]").set("3")
  # Benefit Group
  @browser.text_field(name: "organization[employer_profile_attributes][plan_years_attributes][0][benefit_groups_attributes][0][title]").set("Silver PPO Group")
  @browser.select_list(name: "organization[employer_profile_attributes][plan_years_attributes][0][benefit_groups_attributes][0][reference_plan_id]").select_value(Plan.all.first.id.to_s)
  @browser.select_list(name: "organization[employer_profile_attributes][plan_years_attributes][0][benefit_groups_attributes][0][effective_on_offset]").select_value(30)
  @browser.text_field(name: "organization[employer_profile_attributes][plan_years_attributes][0][benefit_groups_attributes][0][premium_pct_as_int]").set(53)
  @browser.text_field(name: "organization[employer_profile_attributes][plan_years_attributes][0][benefit_groups_attributes][0][employer_max_amt_in_cents]").set(1245)
  # Relationship Benefit
  @browser.select_list(name: "organization[employer_profile_attributes][plan_years_attributes][0][benefit_groups_attributes][0][relationship_benefits_attributes][0][relationship]").select_value("employee")
  @browser.text_field(name: "organization[employer_profile_attributes][plan_years_attributes][0][benefit_groups_attributes][0][relationship_benefits_attributes][0][premium_pct]").set(21)
  @browser.text_field(name: "organization[employer_profile_attributes][plan_years_attributes][0][benefit_groups_attributes][0][relationship_benefits_attributes][0][employer_max_amt]").set(120)
  @browser.text_field(name: "organization[employer_profile_attributes][plan_years_attributes][0][benefit_groups_attributes][0][relationship_benefits_attributes][0][offered]").set("yes")

end

And(/^I should see a second fieldset to enter my name and email$/) do
  # Address
  @browser.select_list(name: "organization[office_locations_attributes][0][address_attributes][kind]").select_value("home")
  @browser.text_field(name: "organization[office_locations_attributes][0][address_attributes][address_1]").set("13101 elm tree dr")
  @browser.text_field(name: "organization[office_locations_attributes][0][address_attributes][address_2]").set("xyz")
  @browser.text_field(name: "organization[office_locations_attributes][0][address_attributes][city]").set("Dunwoody")
  @browser.text_field(name: "organization[office_locations_attributes][0][address_attributes][state]").set("GA")
  @browser.text_field(name: "organization[office_locations_attributes][0][address_attributes][zip]").set("30027")
  #Phone
  @browser.select_list(name: "organization[office_locations_attributes][0][phone_attributes][kind]").select_value("home")
  @browser.text_field(name: "organization[office_locations_attributes][0][phone_attributes][area_code]").set(303)
  @browser.text_field(name: "organization[office_locations_attributes][0][phone_attributes][number]").set(1230981)
  @browser.text_field(name: "organization[office_locations_attributes][0][phone_attributes][extension]").set(1231)
  # Email
  @browser.select_list(name: "organization[office_locations_attributes][0][email_attributes][kind]").select_value("home")
  @browser.text_field(name: "organization[office_locations_attributes][0][email_attributes][address]").set("example1@example.com")
  @browser.button(name: "commit").click
end

And(/^My user data from existing the fieldset values are prefilled using data from my existing account$/) do
  pending
end

And(/^I should see a successful creation message$/) do
  Watir::Wait.until(30) { @browser.text.include?("Employer successfully created.") }
  expect(@browser.a(text: "True First Inc").visible?).to be_truthy
end

When(/^I click on an employer in the employer list$/) do
  @browser.a(text: "True First Inc").click
end

Then(/^I should see the employer information$/) do
  sleep(1)
  expect(@browser.text.include?("True First Inc")).to be_truthy
  expect(@browser.text.include?("13101 elm tree dr\nxyz\nDunwoody, GA 30027\n(303) 123-0981 x 1231")).to be_truthy
  expect(@browser.text.include?("Enrollment\nPlan Year\n2015\nPlan Year Start\n01-01-2015\nOpen Enroll Start/End\n11-01-2014 / 11-30-2014\nFull Time Employees\n35\nParticipation Pct\n100%")).to be_truthy
  expect(@browser.text.include?("Company Details\nFEIN **-***3089\nEntity Kind S Corporation")).to be_truthy
end

When(/^I click on the Employees tab$/) do
  Watir::Wait.until(30) { @browser.text.include?("Employees") }
  sleep(1)
  @browser.a(text: "Employees").click
end

Then(/^I should see the employee family roster$/) do
  sleep(1)
  expect(@browser.text.include?("Employee Roster")).to be_truthy
  expect(@browser.a(text: "Add Employee").visible?).to be_truthy
end

And(/^It should default to active tab$/) do
  sleep(1)
  expect(@browser.radio(id: "terminated_no").set?).to be_truthy
  expect(@browser.radio(id: "terminated_yes").set?).to be_falsey
  expect(@browser.radio(id: "family_waived").set?).to be_falsey
  expect(@browser.radio(id: "family_all").set?).to be_falsey
end

When(/^I click on add employee button$/) do
  Watir::Wait.until(30) { @browser.a(text: "Add Employee").present? }
  sleep(1)
  @browser.a(text: "Add Employee").click
end

Then(/^I should see a form to enter information about employee, address and dependents$/) do
  sleep(1)
  Watir::Wait.until(30) { @browser.input(value: "Create Family").visible? }
  sleep(1)
  expect(@browser.input(value: "Create Family").visible?).to be_truthy
  # Employee
  @browser.text_field(name: "employer_census_employee_family[census_employee_attributes][first_name]").set("John")
  @browser.text_field(name: "employer_census_employee_family[census_employee_attributes][middle_name]").set("K")
  @browser.text_field(name: "employer_census_employee_family[census_employee_attributes][last_name]").set("Doe")
  @browser.text_field(name: "employer_census_employee_family[census_employee_attributes][name_sfx]").set("Jr")
  @browser.text_field(name: "employer_census_employee_family[census_employee_attributes][date_of_birth]").set("10/10/1980")
  @browser.text_field(name: "employer_census_employee_family[census_employee_attributes][ssn]").set("786120965")
  @browser.radio(id: "employer_census_employee_family_census_employee_attributes_gender_male").set
  @browser.text_field(name: "employer_census_employee_family[census_employee_attributes][hired_on]").set("10/10/2014")
  #Address
  @browser.text_field(name: "employer_census_employee_family[census_employee_attributes][address_attributes][address_1]").set("1026 potomac")
  @browser.text_field(name: "employer_census_employee_family[census_employee_attributes][address_attributes][address_2]").set("apt abc")
  @browser.text_field(name: "employer_census_employee_family[census_employee_attributes][address_attributes][city]").set("alpharetta")
  @browser.text_field(name: "employer_census_employee_family[census_employee_attributes][address_attributes][state]").set("GA")
  @browser.text_field(name: "employer_census_employee_family[census_employee_attributes][address_attributes][zip]").set("30228")
  # Dependents
  @browser.text_field(name: "employer_census_employee_family[census_dependents_attributes][0][first_name]").set("Mary")
  @browser.text_field(name: "employer_census_employee_family[census_dependents_attributes][0][last_name]").set("Doe")
  @browser.text_field(name: "employer_census_employee_family[census_dependents_attributes][0][name_sfx]").set("Jr")
  @browser.text_field(name: "employer_census_employee_family[census_dependents_attributes][0][dob]").set("10/12/2012")
  @browser.radio(id: "employer_census_employee_family_census_dependents_attributes_0_gender_female").set
  @browser.text_field(name: "employer_census_employee_family[census_dependents_attributes][0][employee_relationship]").set("child_under_26")
  @browser.input(value: "Create Family").click
end


And(/^I should see a green success message$/) do
  sleep(1)
  Watir::Wait.until(30) {  @browser.text.include?("Employer Census Family is successfully created.") }
  expect(@browser.a(text: "John K Doe Jr").visible?).to be_truthy
  expect(@browser.a(text: "Edit").visible?).to be_truthy
  expect(@browser.a(text: "Terminate").visible?).to be_truthy
  expect(@browser.a(text: "Delink").visible?).to be_truthy
end
