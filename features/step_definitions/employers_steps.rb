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
  user.build_person(first_name: "John", last_name: "Doe", ssn: "111000999", dob: "10/10/1985")
  user.save
  FactoryGirl.create(:plan)
  @browser.text_field(name: "user[email]").set(user.email)
  @browser.text_field(name: "user[password]").set(user.password)
  @browser.input(value: "Sign in").click
end

Then(/^I should see a welcome page with successful sign in message$/) do
  Watir::Wait.until(30) { @browser.text.include?("Signed in successfully.") }
  expect(@browser.text.include?("Signed in successfully.")).to be_truthy
  sleep(1)
  expect(@browser.a(text: "Continue").visible?).to be_truthy
  @browser.a(text: "Continue").click
end

Then(/^I should see fields to search for person and employer$/) do
  sleep(1)
  Watir::Wait.until(30) { @browser.text.include?("Personal Information") }
  expect(@browser.text.include?("Personal Information")).to be_truthy
end

Then(/^I should see an initial fieldset to enter my name, ssn and dob$/) do
  sleep(1)
  @browser.text_field(name: "person[first_name]").set("John")
  @browser.text_field(name: "person[last_name]").set("Doe")
  @browser.text_field(name: "person[date_of_birth]").set("10/10/1985")
  @browser.text_field(name: "person[ssn]").set("111000999")
  expect(@browser.button(value: "Search Person").visible?).to be_truthy
  @browser.button(value: "Search Person").fire_event("onclick")
  sleep(1)

end

And(/^My user data from existing the fieldset values are prefilled using data from my existing account$/) do
  @browser.button(value: "This is my info").fire_event("onclick")
  sleep(1)
  @browser.text_field(name: "person[addresses_attributes][0][address_1]").set("12000 Address 1")
  @browser.text_field(name: "person[addresses_attributes][0][address_2]").set("Suite 100")
  @browser.text_field(name: "person[addresses_attributes][0][city]").set("city")
  @browser.text_field(name: "person[addresses_attributes][0][state]").set("st")
  @browser.text_field(name: "person[addresses_attributes][0][zip]").set("20001")
  @browser.text_field(name: "person[phones_attributes][0][full_phone_number]").set("9999999999")
  @browser.text_field(name: "person[phones_attributes][1][full_phone_number]").set("8888888888")
  @browser.text_field(name: "person[emails_attributes][0][address]").set("home@example.com")
  @browser.text_field(name: "person[emails_attributes][1][address]").set("work@example.com")
  @browser.text_field(name: "person[emails_attributes][1][address]").click
  sleep(1)
  expect(@browser.button(id: "continue-employer").visible?).to be_truthy
  @browser.button(id: "continue-employer").click
  sleep(1)
end

And(/^I should see a second form with a fieldset for Employer information, including: legal name, DBA, fein, entity_kind, broker agency, URL, address, and phone$/) do
  Watir::Wait.until(30) { @browser.button(value: "Search Employers").present? }
  org = Organization.first
  org.build_employer_profile(entity_kind: "partnership")
  org.save

  expect(@browser.button(value: "Search Employers").visible?).to be_truthy
  @browser.text_field(name: "employer_profile[fein]").set(org.fein)
  @browser.text_field(name: "employer_profile[dba]").set("test")
  @browser.text_field(name: "employer_profile[legal_name]").set(org.legal_name)
  @browser.select_list(name: "employer_profile[entity_kind]").select_value(org.employer_profile.entity_kind)
  @browser.button(value: "Search Employers").fire_event("onclick")
  sleep(1)
  @browser.button(value: "This is my employer").fire_event("onclick")
  sleep(1)
   @browser.button(value: "Create").fire_event("onclick")

end

And(/^I should see an initial form with a fieldset for Employer information, including: legal name, DBA, fein, entity_kind, broker agency, URL, address, and phone$/) do
  Watir::Wait.until(30) { @browser.text_field(name: "organization[employer_profile_attributes][fein]").present?}
  sleep(1)
  # Employer info
  @browser.text_field(name: "organization[employer_profile_attributes][fein]").set("678123089")
  @browser.text_field(name: "organization[employer_profile_attributes][dba]").set("test")
  @browser.text_field(name: "organization[employer_profile_attributes][legal_name]").set("True First Inc")
  @browser.select_list(id: "organization_employer_profile_attributes_entity_kind").option(text: "c_corporation")
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

And(/^I should see a successful creation message$/) do
  Watir::Wait.until(30) { @browser.text.include?("Employer successfully created.") }
  expect(@browser.text.include?("Employer successfully created.")).to be_truthy
end

When(/^I click on an employer in the employer list$/) do
  @browser.a(text: "True First Inc").click
end

Then(/^I should see the employer information$/) do
  sleep(3)
  expect(@browser.text.include?("True First Inc")).to be_truthy
  expect(@browser.text.include?("13101 elm tree dr\nxyz\nDunwoody, GA 30027\n(303) 123-0981 x 1231")).to be_truthy
  expect(@browser.text.include?("Enrollment\nNo Plan Years Found")).to be_truthy
  expect(@browser.text.include?("Company Details\nFEIN **-***3089\nEntity Kind C Corporation")).to be_truthy
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
  # Census Employee
  @browser.text_field(name: "employer_census_employee_family[census_employee_attributes][first_name]").set("John")
  @browser.text_field(name: "employer_census_employee_family[census_employee_attributes][middle_name]").set("K")
  @browser.text_field(name: "employer_census_employee_family[census_employee_attributes][last_name]").set("Doe")
  @browser.text_field(name: "employer_census_employee_family[census_employee_attributes][name_sfx]").set("Jr")
  @browser.text_field(name: "employer_census_employee_family[census_employee_attributes][date_of_birth]").set("10/10/1980")
  @browser.text_field(name: "employer_census_employee_family[census_employee_attributes][ssn]").set("786120965")
  @browser.radio(id: "employer_census_employee_family_census_employee_attributes_gender_male").set
  @browser.text_field(name: "employer_census_employee_family[census_employee_attributes][hired_on]").set("10/10/2014")
  # Address
  @browser.text_field(name: "employer_census_employee_family[census_employee_attributes][address_attributes][address_1]").set("1026 potomac")
  @browser.text_field(name: "employer_census_employee_family[census_employee_attributes][address_attributes][address_2]").set("apt abc")
  @browser.text_field(name: "employer_census_employee_family[census_employee_attributes][address_attributes][city]").set("alpharetta")
  @browser.text_field(name: "employer_census_employee_family[census_employee_attributes][address_attributes][state]").set("GA")
  @browser.text_field(name: "employer_census_employee_family[census_employee_attributes][address_attributes][zip]").set("30228")
  # Census Dependents
  @browser.text_field(name: "employer_census_employee_family[census_dependents_attributes][0][first_name]").set("Mary")
  @browser.text_field(name: "employer_census_employee_family[census_dependents_attributes][0][last_name]").set("Doe")
  @browser.text_field(name: "employer_census_employee_family[census_dependents_attributes][0][name_sfx]").set("Jr")
  @browser.text_field(name: "employer_census_employee_family[census_dependents_attributes][0][dob]").set("10/12/2012")
  @browser.radio(id: "employer_census_employee_family_census_dependents_attributes_0_gender_female").set
  @browser.text_field(name: "employer_census_employee_family[census_dependents_attributes][0][employee_relationship]").set("child_under_26")
  @browser.input(value: "Create Family").click
end

And(/^I should see employer census family created success message$/) do
  sleep(1)
  Watir::Wait.until(30) {  @browser.text.include?("Employer Census Family is successfully created.") }
  expect(@browser.a(text: "John K Doe Jr").visible?).to be_truthy
  expect(@browser.a(text: "Edit").visible?).to be_truthy
  expect(@browser.a(text: "Terminate").visible?).to be_truthy
  expect(@browser.a(text: "Delink").visible?).to be_truthy
end

When(/^I click on Edit family button for a census family$/) do
  sleep(1)
  Watir::Wait.until(30) { @browser.a(text: "Edit").visible? }
  @browser.a(text: "Edit").click
end

Then(/^I should see a form to update the contents of the census employee$/) do
  sleep(1)
  Watir::Wait.until(30) { @browser.input(value: "Update Family").visible? }
  expect(@browser.input(value: "Update Family").visible?).to be_truthy
  @browser.text_field(name: "employer_census_employee_family[census_employee_attributes][first_name]").set("Patrick")
  @browser.text_field(name: "employer_census_employee_family[census_employee_attributes][address_attributes][state]").set("VA")
  @browser.input(value: "Update Family").click
end

And(/^I should see employer census family updated success message$/) do
  sleep(1)
  Watir::Wait.until(30) {  @browser.text.include?("Employer Census Family is successfully updated.") }
  expect(@browser.a(text: "Patrick K Doe Jr").visible?).to be_truthy
end

When(/^I click on terminate button for a census family$/) do
  sleep(1)
  Watir::Wait.until(30) { @browser.a(text: "Terminate").visible? }
  @browser.a(text: "Terminate").click
  sleep(1)
  expect(@browser.a(text: "Patrick K Doe Jr").visible?).to be_falsey
end

Then(/^The census family should be terminated and move to terminated tab$/) do
  @browser.radio(id: "terminated_yes").fire_event("onclick")
  sleep(1)
  expect(@browser.a(text: "Patrick K Doe Jr").visible?).to be_truthy
  expect(@browser.a(text: "Rehire").visible?).to be_truthy
end

And(/^I should see the census family is successfully terminated message$/) do
  sleep(1)
  Watir::Wait.until(30) {  @browser.text.include?("Successfully terminated family.") }
end

When(/^I click on Rehire button for a census family on terminated tab$/) do
  sleep(1)
  Watir::Wait.until(30) { @browser.a(text: "Rehire").visible? }
  @browser.a(text: "Rehire").click
end

Then(/^A new instance of the census family should be created$/) do
  sleep(1)
  @browser.radio(id: "terminated_no").fire_event("onclick")
  sleep(1)
  expect(@browser.text.include?("Patrick K Doe Jr")).to be_truthy
  expect(@browser.a(text: "Terminate").visible?).to be_truthy
end

And(/^I should see the census family is successfully rehired message$/) do
  sleep(1)
  Watir::Wait.until(30) {  @browser.text.include?("Successfully rehired family.") }
end


When(/^I go to the benefits tab I should see plan year information$/) do
  sleep(1)
  @browser.refresh
  sleep(1)
  Watir::Wait.until(30) { @browser.text.include?("Benefits") }
  expect(@browser.text.include?("Benefits")).to be_truthy
  @browser.a(text: "Benefits").click
end


And(/^I should see a button to create new plan year$/) do
  sleep(1)
  expect(@browser.a(text: "Add Plan Year").visible?).to be_truthy
  @browser.a(text: "Add Plan Year").click

end

And(/^I should be able to add information about plan year, benefits and relationship benefits$/) do
#Plan Year
  sleep(1)
  @browser.text_field(name: "plan_year[start_on]").set("01/01/2015")
  @browser.text_field(name: "plan_year[end_on]").set("12/31/2015")
  @browser.text_field(name: "plan_year[open_enrollment_start_on]").set("11/01/2014")
  @browser.text_field(name: "plan_year[open_enrollment_end_on]").set("11/30/2014")
  @browser.text_field(name: "plan_year[fte_count]").set("35")
  @browser.text_field(name: "plan_year[pte_count]").set("15")
  @browser.text_field(name: "plan_year[msp_count]").set("3")
  # Benefit Group
  @browser.text_field(name: "plan_year[benefit_groups_attributes][0][title]").set("Silver PPO Group")
  @browser.select_list(name: "plan_year[benefit_groups_attributes][0][reference_plan_id]").select_value(Plan.all.first.id.to_s)
  @browser.radio(id: "plan_year_benefit_groups_attributes_0_effective_on_offset_30").fire_event("onclick")
  @browser.text_field(name: "plan_year[benefit_groups_attributes][0][premium_pct_as_int]").set(53)
  @browser.text_field(name: "plan_year[benefit_groups_attributes][0][employer_max_amt_in_cents]").set(1245)
  # Relationship Benefit
  @browser.select_list(name: "plan_year[benefit_groups_attributes][0][relationship_benefits_attributes][0][relationship]").select_value("employee")
  @browser.text_field(name: "plan_year[benefit_groups_attributes][0][relationship_benefits_attributes][0][premium_pct]").set(21)
  @browser.text_field(name: "plan_year[benefit_groups_attributes][0][relationship_benefits_attributes][0][employer_max_amt]").set(120)
  @browser.text_field(name: "plan_year[benefit_groups_attributes][0][relationship_benefits_attributes][0][offered]").set("yes")
  @browser.input(value: "Create Plan Year").click
end


And(/^I should see a success message after clicking on create plan year button$/) do
  sleep(1)
  Watir::Wait.until(30) {  @browser.text.include?("Plan Year successfully created.") }
end