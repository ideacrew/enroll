Given(/^I haven't signed up as an HBX user$/) do
  sleep(1)
end

When(/^I visit the Employer portal$/) do
  @browser.goto("http://localhost:3000/")
  Watir::Wait.until(30) { @browser.a(text: "Employer Portal").present? }
  sleep(1)
  @browser.a(text: "Employer Portal").click
  screenshot("employer_start")
  Watir::Wait.until(30) { @browser.a(text: "Create account").present? }
  sleep(1)
  @browser.a(text: "Create account").click
end

And(/^I sign up with valid user data$/) do
  Watir::Wait.until(30) { @browser.text_field(name: "user[password_confirmation]").present? }
  @browser.text_field(name: "user[email]").set("trey.evans#{rand(100)}@dc.gov")
  @browser.text_field(name: "user[password]").set("12345678")
  @browser.text_field(name: "user[password_confirmation]").set("12345678")
  screenshot("employer_create_account")
  @browser.input(value: "Create account").click
end

Then(/^I should see a successful sign up message$/) do
  Watir::Wait.until(30) { @browser.element(text: /Welcome! Your account has been created./).present? }
  screenshot("employer_sign_up_welcome")
  expect(@browser.element(text: /Welcome! Your account has been created./).visible?).to be_truthy
end

And(/^I should see an initial form to enter information about my Employer and myself$/) do
  sleep(1)
  expect(@browser.a(text: "Continue").visible?).to be_truthy
  @browser.a(text: "Continue").click
  sleep(1)
  plan = FactoryGirl.create(:plan)
  pt = plan.premium_tables.build(age: 34, start_on: 0.days.ago.beginning_of_year.to_date, end_on: 0.days.ago.end_of_year.to_date, cost: 345.09)
  pt1 = plan.premium_tables.build(age: 3, start_on: 0.days.ago.beginning_of_year.to_date, end_on: 0.days.ago.end_of_year.to_date, cost: 125.10)
  plan.save
  @browser.text_field(name: "person[first_name]").set("Doe")
  @browser.text_field(name: "person[last_name]").set("John")
  @browser.text_field(name: "person[date_of_birth]").set("11/10/1982")
  @browser.text_field(name: "person[first_name]").click
  @browser.text_field(name: "person[ssn]").set("111010999")
  expect(@browser.button(value: "Search Person").visible?).to be_truthy
  @browser.button(value: "Search Person").fire_event("onclick")
  sleep(1)
  screenshot("employer_portal_person_search_no_match")

  @browser.button(value: "Create Person").fire_event("onclick")
  sleep(1)
  @browser.text_field(name: "person[addresses_attributes][0][address_1]").set("100 North Street")
  @browser.text_field(name: "person[addresses_attributes][0][address_2]").set("Suite 990")
  @browser.text_field(name: "person[addresses_attributes][0][city]").set("Sterling")
  @browser.text_field(name: "person[addresses_attributes][0][state]").set("VA")
  @browser.text_field(name: "person[addresses_attributes][0][zip]").set("20166")
  @browser.text_field(name: "person[phones_attributes][0][full_phone_number]").set("6781230986")
  @browser.text_field(name: "person[phones_attributes][1][full_phone_number]").set("6781230987")
  @browser.text_field(name: "person[emails_attributes][0][address]").set("john.doe@home.com")
  @browser.text_field(name: "person[emails_attributes][1][address]").set("john.doe@work.com")
  @browser.text_field(name: "person[emails_attributes][1][address]").click
  screenshot("employer_portal_person_data_new")
  sleep(1)
  expect(@browser.button(id: "continue-employer").visible?).to be_truthy
  @browser.button(id: "continue-employer").click
  sleep(3)
  @browser.text_field(name: "employer_profile[legal_name]").set("Turner Agency, Inc")
  @browser.text_field(name: "employer_profile[dba]").set("Turner Brokers")
  @browser.text_field(name: "employer_profile[fein]").set("678121089")
  input_field = @browser.div(:class => 'selectric-wrapper')
  input_field.click
  input_field.li(text: "Partnership").click
  sleep(1)
  @browser.button(value: "Search Employers").fire_event("onclick")
  sleep(1)
  screenshot("employer_portal_employer_search_no_match")
  sleep(1)
  @browser.button(value: "Create Employer").fire_event("onclick")
  sleep(3)
  @browser.text_field(name: "organization[office_locations_attributes][0][address_attributes][address_1]").set("981 North State")
  @browser.text_field(name: "organization[office_locations_attributes][0][address_attributes][address_2]").set("Suite 2a")
  @browser.text_field(name: "organization[office_locations_attributes][0][address_attributes][city]").set("Springfield")
  @browser.text_field(name: "organization[office_locations_attributes][0][address_attributes][state]").set("VA")
  @browser.text_field(name: "organization[office_locations_attributes][0][address_attributes][zip]").set("93833")
  @browser.text_field(name: "organization[office_locations_attributes][0][phone_attributes][area_code]").set("898")
  @browser.text_field(name: "organization[office_locations_attributes][0][phone_attributes][number]").set("9990000")
  @browser.text_field(name: "organization[office_locations_attributes][0][phone_attributes][extension]").set("1111")
  @browser.text_field(name: "organization[office_locations_attributes][0][email_attributes][address]").set("john.doe.abcsystems@example.com")
  screenshot("employer_portal_employer_data_new")
  @browser.button(value: "Create").fire_event("onclick")
  sleep(1)
end

Given(/^I have signed up previously through consumer, broker agency or previous visit to the Employer portal$/) do
end

When(/^I visit the Employer portal to sign in$/) do
  @browser.goto("http://localhost:3000/")
  screenshot("employer_start")
  Watir::Wait.until(30) { @browser.a(text: "Employer Portal").present? }
  sleep(1)
  @browser.a(text: "Employer Portal").click
end

And(/^I sign in with valid user data$/) do
  Watir::Wait.until(30) { @browser.input(value: "Sign in").present? }
  user = FactoryGirl.create(:user)
  user.build_person(first_name: "John", last_name: "Doe", ssn: "111000999", dob: "10/10/1985")
  user.save
  plan = FactoryGirl.create(:plan)
  pt = plan.premium_tables.build(age: 34, start_on: 0.days.ago.beginning_of_year.to_date, end_on: 0.days.ago.end_of_year.to_date, cost: 345.09)
  pt1 = plan.premium_tables.build(age: 3, start_on: 0.days.ago.beginning_of_year.to_date, end_on: 0.days.ago.end_of_year.to_date, cost: 125.10)
  plan.save

  @browser.text_field(name: "user[email]").set(user.email)
  @browser.text_field(name: "user[password]").set(user.password)
  screenshot("employer_portal_sign_in")
  @browser.input(value: "Sign in").click
end

Then(/^I should see a welcome page with successful sign in message$/) do
  Watir::Wait.until(30) { @browser.text.include?("Signed in successfully.") }
  screenshot("employer_portal_sign_in_welcome")
  expect(@browser.text.include?("Signed in successfully.")).to be_truthy
  sleep(1)
  expect(@browser.a(text: "Continue").visible?).to be_truthy
  @browser.a(text: "Continue").click
end

Then(/^I should see fields to search for person and employer$/) do
  sleep(2)
  Watir::Wait.until(30) { @browser.text.include?("Personal Information") }
  screenshot("employer_portal_person_search")
  expect(@browser.text.include?("Personal Information")).to be_truthy
end

Then(/^I should see an initial fieldset to enter my name, ssn and dob$/) do
  sleep(1)
  @browser.text_field(name: "person[first_name]").set("John")
  @browser.text_field(name: "person[last_name]").set("Doe")
  @browser.text_field(name: "person[date_of_birth]").set("10/10/1985")
  @browser.text_field(name: "person[first_name]").click
  @browser.text_field(name: "person[ssn]").set("111000999")
  expect(@browser.button(value: "Search Person").visible?).to be_truthy
  screenshot("employer_portal_person_search_criteria")
  @browser.button(value: "Search Person").fire_event("onclick")
end

And(/^My user data from existing the fieldset values are prefilled using data from my existing account$/) do
  sleep(1)
  Watir::Wait.until(30) { @browser.button(value: "This is my info").visible? }
  screenshot("employer_portal_person_match_form")
  @browser.button(value: "This is my info").fire_event("onclick")
  sleep(2)
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
  screenshot("employer_portal_person_data")
  sleep(1)
  expect(@browser.button(id: "continue-employer").visible?).to be_truthy
  @browser.button(id: "continue-employer").click
  sleep(1)
end

And(/^I should see a form with a fieldset for Employer information, including: legal name, DBA, fein, entity_kind, broker agency, URL, address, and phone$/) do
  sleep(1)
  Watir::Wait.until(30) { @browser.button(value: "Search Employers").present? }
  screenshot("employer_portal_employer_search_form")
  @employer_profile = FactoryGirl.create(:employer_profile)

  expect(@browser.button(value: "Search Employers").visible?).to be_truthy
  @browser.text_field(name: "employer_profile[legal_name]").set(@employer_profile.legal_name)
  @browser.text_field(name: "employer_profile[dba]").set(@employer_profile.dba)
  @browser.text_field(name: "employer_profile[fein]").set(@employer_profile.fein)
  screenshot("employer_portal_employer_search_criteria")
  @browser.button(value: "Search Employers").fire_event("onclick")
  sleep(1)
  screenshot("employer_portal_employer_contact_info")
  @browser.button(value: "This is my employer").fire_event("onclick")
  sleep(1)
  @browser.button(value: "Create").fire_event("onclick")
end

And(/^I should see a successful creation message$/) do
  Watir::Wait.until(30) { @browser.text.include?("Employer successfully created.") }
  screenshot("employer_create_success_message")
  expect(@browser.text.include?("Employer successfully created.")).to be_truthy
end

When(/^I click on an employer in the employer list$/) do
  sleep(1)
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
  sleep(1)
  @browser.refresh
  sleep(1)
  Watir::Wait.until(30) { @browser.text.include?("Employees") }
  sleep(1)
  @browser.a(text: "Employees").click
end

Then(/^I should see the employee family roster$/) do
  sleep(1)
  expect(@browser.text.include?("Employee Roster")).to be_truthy
  screenshot("employer_census_family")
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

Then(/^I should see a form to enter information about employee, address and dependents details$/) do
  sleep(1)
  Watir::Wait.until(30) { @browser.input(value: "Create Family").visible? }
  sleep(1)
  expect(@browser.input(value: "Create Family").visible?).to be_truthy
  screenshot("employer_census_new_family")
  # Census Employee
  @browser.text_field(name: "employer_census_employee_family[census_employee_attributes][first_name]").set("John")
  @browser.text_field(name: "employer_census_employee_family[census_employee_attributes][middle_name]").set("K")
  @browser.text_field(name: "employer_census_employee_family[census_employee_attributes][last_name]").set("Doe")
  @browser.text_field(name: "employer_census_employee_family[census_employee_attributes][name_sfx]").set("Jr")
  @browser.text_field(name: "employer_census_employee_family[census_employee_attributes][dob]").set("10/10/1980")
  @browser.text_field(name: "employer_census_employee_family[census_employee_attributes][ssn]").click
  @browser.text_field(name: "employer_census_employee_family[census_employee_attributes][ssn]").set("786120965")
  @browser.radio(id: "employer_census_employee_family_census_employee_attributes_gender_male").set
  @browser.text_field(name: "employer_census_employee_family[census_employee_attributes][hired_on]").set("10/10/2014")
  # Address
  @browser.text_field(name: "employer_census_employee_family[census_employee_attributes][address_attributes][address_1]").set("1026 potomac")
  @browser.text_field(name: "employer_census_employee_family[census_employee_attributes][address_attributes][address_1]").set("1026 potomac")
  @browser.text_field(name: "employer_census_employee_family[census_employee_attributes][address_attributes][address_2]").set("apt abc")
  @browser.text_field(name: "employer_census_employee_family[census_employee_attributes][address_attributes][city]").set("alpharetta")
  @browser.text_field(name: "employer_census_employee_family[census_employee_attributes][address_attributes][state]").set("GA")
  @browser.text_field(name: "employer_census_employee_family[census_employee_attributes][address_attributes][zip]").set("30228")
  input_field = @browser.divs(:class => 'selectric-wrapper').last
  input_field.click
  input_field.li(text: "Silver PPO Group").click
  # Census Dependents
  # @browser.text_field(name: "employer_census_employee_family[census_dependents_attributes][0][first_name]").set("Mary")
  # @browser.text_field(name: "employer_census_employee_family[census_dependents_attributes][0][middle_name]").set("K")
  # @browser.text_field(name: "employer_census_employee_family[census_dependents_attributes][0][last_name]").set("Doe")
  # @browser.text_field(name: "employer_census_employee_family[census_dependents_attributes][0][dob]").set("10/12/2012")
  # @browser.radio(id: "employer_census_employee_family_census_dependents_attributes_0_gender_female").set
  # screenshot("employer_census_new_family_with_data")
  # input_field = @browser.divs(:class => 'selectric-wrapper').first
  # input_field.click
  # input_field.li(text: "Child under 26").click
  # @browser.text_field(name: "employer_census_employee_family[census_dependents_attributes][0][employee_relationship]").set("child_under_26")
  @browser.input(value: "Create Family").click
end

And(/^I should see employer census family created success message$/) do
  sleep(2)
  Watir::Wait.until(30) {  @browser.text.include?("Employer Census Family is successfully created.") }
  screenshot("employer_census_new_family_success_message")
  @browser.refresh
  sleep(1)
  @browser.a(text: "Employees").click
  sleep(1)
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
  Watir::Wait.until(30) { @browser.input(value: "Update Family").present? }
  expect(@browser.input(value: "Update Family").visible?).to be_truthy
  @browser.text_field(name: "employer_census_employee_family[census_employee_attributes][first_name]").set("Patrick")
  @browser.text_field(name: "employer_census_employee_family[census_employee_attributes][address_attributes][state]").set("VA")
  input_field = @browser.divs(:class => 'selectric-wrapper').last
  input_field.click
  input_field.li(text: "Silver PPO Group").click
  @browser.input(value: "Update Family").click
end

And(/^I should see employer census family updated success message$/) do
  sleep(2)
  Watir::Wait.until(30) {  @browser.text.include?("Employer Census Family is successfully updated.") }
  # expect(@browser.a(text: "Patrick K Doe Jr").visible?).to be_truthy
end

And(/^I logout from employer portal$/) do
  @browser.goto("http://localhost:3000/")
  Watir::Wait.until(30) {  @browser.a(text: "Logout").visible? }
  @browser.a(text: "Logout").click
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
  Watir::Wait.until(30) { @browser.text.include?("Benefits") }
  expect(@browser.text.include?("Benefits")).to be_truthy
  @browser.a(text: "Benefits").click
end


And(/^I should see a button to create new plan year$/) do
  sleep(1)
  expect(@browser.a(text: "Add Plan Year").visible?).to be_truthy
  screenshot("employer_plan_year")
  @browser.a(text: "Add Plan Year").click
end

And(/^I should be able to add information about plan year, benefits and relationship benefits$/) do
#Plan Year
  Watir::Wait.until(10) { @browser.text_field(name: "plan_year[start_on]").present? }
  screenshot("employer_add_plan_year")
  @browser.text_field(name: "plan_year[start_on]").set("01/01/2015")
  @browser.text_field(name: "plan_year[end_on]").set("12/31/2015")
  @browser.text_field(name: "plan_year[open_enrollment_start_on]").set("11/01/2014")
  @browser.text_field(name: "plan_year[open_enrollment_end_on]").set("11/30/2014")
  @browser.text_field(name: "plan_year[fte_count]").click
  @browser.text_field(name: "plan_year[fte_count]").set("35")
  @browser.text_field(name: "plan_year[pte_count]").set("15")
  @browser.text_field(name: "plan_year[msp_count]").set("3")
  # Benefit Group
  @browser.text_field(name: "plan_year[benefit_groups_attributes][0][title]").set("Silver PPO Group")
  radio = @browser.div(class: "btn-group")
  radio.click
  @browser.select_list(id: "plan_year_benefit_groups_attributes_0_effective_on_offset")
  # @browser.radio(id: "plan_year_benefit_groups_attributes_0_effective_on_offset_30").fire_event("onclick")
  @browser.text_field(name: "plan_year[benefit_groups_attributes][0][premium_pct_as_int]").set(53)
  @browser.text_field(name: "plan_year[benefit_groups_attributes][0][employer_max_amt_in_cents]").set(1245)
  # Relationship Benefit
  @browser.select_list(name: "plan_year[benefit_groups_attributes][0][relationship_benefits_attributes][0][relationship]").select_value("employee")
  @browser.text_field(name: "plan_year[benefit_groups_attributes][0][relationship_benefits_attributes][0][premium_pct]").set(21)
  @browser.text_field(name: "plan_year[benefit_groups_attributes][0][relationship_benefits_attributes][0][employer_max_amt]").set(120)
  @browser.text_field(name: "plan_year[benefit_groups_attributes][0][relationship_benefits_attributes][0][offered]").set("true")

  expect(@browser.a(class: "add_fields").visible?).to be_truthy
  @browser.a(class: "add_fields").click
  @browser.fieldsets.last.p(class: /label/, text: /Employee/).click
  @browser.fieldsets.last.li(text:/Child under 26/).click
  @browser.text_fields(name: /plan_year.benefit_groups_attributes.+relationship_benefits_attributes.+premium_pct/).last.set("15")
  @browser.text_fields(name: /plan_year.benefit_groups_attributes.+relationship_benefits_attributes.+employer_max_amt/).last.set("51")
  @browser.text_fields(name: /plan_year.benefit_groups_attributes.+relationship_benefits_attributes.+offered/).last.set("true")
  screenshot("employer_add_plan_year_info")
  @browser.input(value: "Create Plan Year").click
end


And(/^I should see a success message after clicking on create plan year button$/) do
  sleep(1)
  screenshot("employer_plan_year_success_message")
  Watir::Wait.until(30) {  @browser.text.include?("Plan Year successfully created.") }
end

When(/^I enter filter in plan selection page$/) do
  Watir::Wait.until(30) { @browser.a(:text => "All Filters").present? }
  @browser.a(:text => "All Filters").click
  @browser.checkboxes(:class => "plan-type-selection-filter").first.set(true)
  @browser.button(:class => "apply-btn", :text => "Apply").click
end

When(/^I enter combind filter in plan selection page$/) do
  @browser.a(:text => "All Filters").click
  @browser.checkboxes(:class => "plan-type-selection-filter").first.set(false)
  # Nationwide
  @browser.checkboxes(:class => "plan-metal-network-selection-filter").last.set(true)
  # Platinum
  @browser.checkboxes(:class => "plan-metal-level-selection-filter")[1].set(true)
  @browser.text_field(:class => "plan-metal-deductible-from-selection-filter").set("")
  @browser.text_field(:class => "plan-metal-deductible-to-selection-filter").set("")
  @browser.text_field(:class => "plan-metal-premium-from-selection-filter").set("$460")
  @browser.text_field(:class => "plan-metal-premium-to-selection-filter").set("$480")
  @browser.button(:class => "apply-btn", :text => "Apply").click
end

Then(/^I should see the combind filter results$/) do
  @browser.divs(:class => "plan-row").select(&:visible?).each do |plan|
    expect(plan.text.include?("DC Area Network")).to eq true
    expect(plan.text.include?("Silver")).to eq true
    expect(plan.p(text: "$470.19").visible?).to eq true
  end
end
