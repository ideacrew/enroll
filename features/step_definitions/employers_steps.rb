Given(/^I haven't signed up as an HBX user$/) do
end

When(/^I visit the Employer portal$/) do
  @browser.goto("http://localhost:3000/")
  @browser.a(text: /Employer Portal/).wait_until_present
  @browser.a(text: /Employer Portal/).click
  screenshot("employer_start")
  @browser.a(text: /Create account/).wait_until_present
  @browser.a(text: /Create account/).click
end

And(/^I sign up with valid user data$/) do
  @browser.text_field(name: "user[password_confirmation]").wait_until_present
  @browser.text_field(name: "user[email]").set("trey.evans#{rand(100)}@dc.gov")
  @browser.text_field(name: "user[password]").set("12345678")
  @browser.text_field(name: "user[password_confirmation]").set("12345678")
  screenshot("employer_create_account")
  @browser.input(value: /Create account/).click
end

Then(/^I should see a successful sign up message$/) do
  Watir::Wait.until(30) { @browser.element(text: /Welcome! Your account has been created./).present? }
  screenshot("employer_sign_up_welcome")
  expect(@browser.element(text: /Welcome! Your account has been created./).visible?).to be_truthy
end

And(/^I should see an initial form to enter information about my Employer and myself$/) do
  @browser.a(text: /Continue/).wait_until_present
  @browser.a(text: /Continue/).click
  @browser.text_field(name: "person[first_name]").wait_until_present
  plan = FactoryGirl.create(:plan)
  pt = plan.premium_tables.build(age: 34, start_on: 0.days.ago.beginning_of_year.to_date, end_on: 0.days.ago.end_of_year.to_date, cost: 345.09)
  pt1 = plan.premium_tables.build(age: 3, start_on: 0.days.ago.beginning_of_year.to_date, end_on: 0.days.ago.end_of_year.to_date, cost: 125.10)
  plan.save
  @browser.text_field(name: "person[first_name]").set("Doe")
  @browser.text_field(name: "person[last_name]").set("John")
  @browser.text_field(name: "person[date_of_birth]").set("11/10/1982")
  @browser.text_field(name: "person[first_name]").click
  @browser.text_field(name: "person[ssn]").set("111010999")
  @browser.button(value: /Search Person/).wait_until_present
  @browser.button(value: /Search Person/).fire_event("onclick")
  @browser.button(value: /Create Person/).wait_until_present
  screenshot("employer_portal_person_search_no_match")

  @browser.button(value: /Create Person/).fire_event("onclick")
  @browser.text_field(name: "person[addresses_attributes][0][address_1]").wait_until_present
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
  @browser.button(id: /continue-employer/).wait_until_present
  @browser.button(id: /continue-employer/).click
  @browser.text_field(name: "employer_profile[legal_name]").wait_until_present
  @browser.text_field(name: "employer_profile[legal_name]").set("Turner Agency, Inc")
  @browser.text_field(name: "employer_profile[dba]").set("Turner Brokers")
  @browser.text_field(name: "employer_profile[fein]").set("678121089")
  input_field = @browser.div(class: /selectric-wrapper/)
  input_field.click
  input_field.li(text: /Partnership/).click
  @browser.button(value: /Search Employers/).wait_until_present
  @browser.button(value: /Search Employers/).fire_event("onclick")
  screenshot("employer_portal_employer_search_no_match")
  @browser.button(value: /Create Employer/).wait_until_present
  @browser.button(value: /Create Employer/).fire_event("onclick")
  @browser.text_field(name: "organization[office_locations_attributes][0][address_attributes][address_1]").wait_until_present
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
  @browser.button(value: /Create/).fire_event("onclick")
end

Given(/^I have signed up previously through consumer, broker agency or previous visit to the Employer portal$/) do
end

When(/^I visit the Employer portal to sign in$/) do
  @browser.goto("http://localhost:3000/")
  screenshot("employer_start")
  @browser.a(text: /Employer Portal/).wait_until_present
  @browser.a(text: /Employer Portal/).click
end

And(/^I sign in with valid user data$/) do
  @browser.input(value: /Sign in/).wait_until_present
  user = FactoryGirl.create(:user)
  user.build_person(first_name: "John", last_name: "Doe", ssn: "111000999", dob: "10/10/1985")
  user.save

  @browser.text_field(name: "user[email]").set(user.email)
  @browser.text_field(name: "user[password]").set(user.password)
  screenshot("employer_portal_sign_in")
  @browser.input(value: /Sign in/).click
end

Then(/^I should see a welcome page with successful sign in message$/) do
  Watir::Wait.until(30) { @browser.text.include?(/Signed in successfully./) }
  screenshot("employer_portal_sign_in_welcome")
  expect(@browser.text.include?("Signed in successfully.")).to be_truthy
  @browser.a(text: /Continue/).wait_until_present
  expect(@browser.a(text: /Continue/).visible?).to be_truthy
  @browser.a(text: /Continue/).click
end

Then(/^I should see fields to search for person and employer$/) do
  Watir::Wait.until(30) { @browser.text.include?(/Personal Information/) }
  screenshot("employer_portal_person_search")
  expect(@browser.text.include?(/Personal Information/)).to be_truthy
end

Then(/^I should see an initial fieldset to enter my name, ssn and dob$/) do
  @browser.text_field(name: "person[first_name]").wait_until_present
  @browser.text_field(name: "person[first_name]").set("John")
  @browser.text_field(name: "person[last_name]").set("Doe")
  @browser.text_field(name: "person[date_of_birth]").set("10/10/1985")
  @browser.text_field(name: "person[first_name]").click
  @browser.text_field(name: "person[ssn]").set("111000999")
  @browser.button(value: /Search Person/).wait_until_present
  screenshot("employer_portal_person_search_criteria")
  @browser.button(value: /Search Person/).fire_event("onclick")
end

And(/^My user data from existing the fieldset values are prefilled using data from my existing account$/) do
  @browser.button(value: /This is my info/).wait_until_present
  screenshot("employer_portal_person_match_form")
  @browser.button(value: /This is my info/).fire_event("onclick")
  @browser.text_field(name: "person[addresses_attributes][0][address_1]").wait_until_present
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
  @browser.button(id: /continue-employer/).wait_until_present
  expect(@browser.button(id: /continue-employer/).visible?).to be_truthy
  @browser.button(id: /continue-employer/).click
end

And(/^I should see a form with a fieldset for Employer information, including: legal name, DBA, fein, entity_kind, broker agency, URL, address, and phone$/) do
  @browser.button(value: /Search Employers/).wait_until_present
  screenshot("employer_portal_employer_search_form")
  @employer_profile = FactoryGirl.create(:employer_profile)

  @browser.text_field(name: "employer_profile[legal_name]").set(@employer_profile.legal_name)
  @browser.text_field(name: "employer_profile[dba]").set(@employer_profile.dba)
  @browser.text_field(name: "employer_profile[fein]").set(@employer_profile.fein)
  screenshot("employer_portal_employer_search_criteria")
  @browser.button(value: /Search Employers/).fire_event("onclick")
  screenshot("employer_portal_employer_contact_info")
  @browser.button(value: /This is my employer/).fire_event("onclick")
  @browser.button(value: /Create/).wait_until_present
  @browser.button(value: /Create/).fire_event("onclick")
end

And(/^I should see a successful creation message$/) do
  Watir::Wait.until(30) { @browser.text.include?("Employer successfully created.") }
  screenshot("employer_create_success_message")
  expect(@browser.text.include?("Employer successfully created.")).to be_truthy
end

When(/^I click on an employer in the employer list$/) do
  @browser.a(text: /True First Inc/).wait_until_present
  @browser.a(text: /True First Inc/).click
end

Then(/^I should see the employer information$/) do
  @browser.text.include?("True First Inc").wait_until_present
  expect(@browser.text.include?("True First Inc")).to be_truthy
  expect(@browser.text.include?("13101 elm tree dr\nxyz\nDunwoody, GA 30027\n(303) 123-0981 x 1231")).to be_truthy
  expect(@browser.text.include?("Enrollment\nNo Plan Years Found")).to be_truthy
  expect(@browser.text.include?("Company Details\nFEIN **-***3089\nEntity Kind C Corporation")).to be_truthy
end

When(/^I click on the Employees tab$/) do
  @browser.refresh
  @browser.a(text: /Employees/).wait_until_present
  @browser.a(text: /Employees/).click
end

Then(/^I should see the employee family roster$/) do
  @browser.a(text: /Add Employee/).wait_until_present
  screenshot("employer_census_family")
  expect(@browser.a(text: /Add Employee/).visible?).to be_truthy
end

And(/^It should default to active tab$/) do
  @browser.radio(id: "terminated_no").wait_until_present
  expect(@browser.radio(id: "terminated_no").set?).to be_truthy
  expect(@browser.radio(id: "terminated_yes").set?).to be_falsey
  expect(@browser.radio(id: "family_waived").set?).to be_falsey
  expect(@browser.radio(id: "family_all").set?).to be_falsey
end

When(/^I click on add employee button$/) do
  @browser.a(text: /Add Employee/).wait_until_present
  @browser.a(text: /Add Employee/).click
end

Then(/^I should see a form to enter information about employee, address and dependents details$/) do
  @browser.element(class: /interaction-click-control-create-employee/).wait_until_present
  screenshot("create_census_employee")
  # Census Employee
  @browser.text_field(class: /interaction-field-control-census-employee-first-name/).wait_until_present
  @browser.text_field(class: /interaction-field-control-census-employee-first-name/).set("John")
  @browser.text_field(class: /interaction-field-control-census-employee-middle-name/).set("K")
  @browser.text_field(class: /interaction-field-control-census-employee-last-name/).set("Doe")
  @browser.text_field(class: /interaction-field-control-census-employee-name-sfx/).set("Jr")
  @browser.text_field(class: /interaction-field-control-census-employee-dob/).set("01/01/1980")
  @browser.text_field(class: /interaction-field-control-census-employee-ssn/).set("786120965")
  @browser.radio(class: /interaction-choice-control-value-census-employee-gender-male/).set
  @browser.text_field(class: /interaction-field-control-census-employee-hired-on/).set("10/10/2014")
  @browser.checkbox(class: /interaction-choice-control-value-census-employee-is-business-owner/).set
  input_field = @browser.divs(class: /selectric-wrapper/).first
  input_field.click
  input_field.li(text: /Silver PPO Group/).click
  # Address
  @browser.text_field(class: /interaction-field-control-census-employee-address-attributes-address-1/).wait_until_present
  @browser.text_field(class: /interaction-field-control-census-employee-address-attributes-address-1/).set("1026 Potomac")
  @browser.text_field(class: /interaction-field-control-census-employee-address-attributes-address-2/).set("apt abc")
  @browser.text_field(class: /interaction-field-control-census-employee-address-attributes-city/).set("Alpharetta")
  @browser.text_field(class: /interaction-field-control-census-employee-address-attributes-state/).set("GA")
  @browser.text_field(class: /interaction-field-control-census-employee-address-attributes-zip/).set("30228")
  # Census Dependents
  # @browser.text_field(class: /interaction-field-control-census-employee-census-dependents-attributes-0-first-name/).set("Mary")
  # @browser.text_field(class: /interaction-field-control-census-employee-census-dependents-attributes-0-middle-name/).set("K")
  # @browser.text_field(class: /interaction-field-control-census-employee-census-dependents-attributes-0-last-name/).set("Doe")
  # @browser.text_field(class: /interaction-field-control-census-employee-census-dependents-attributes-0-dob/).set("10/12/2012")
  # @browser.radio(class: /interaction-choice-control-value-census-employee-census-dependents-attributes-0-gender-female/).set
  # input_field = @browser.divs(class: "selectric-wrapper").last
  # input_field.click
  # input_field.li(text: /Child under 26/).click
  screenshot("create_census_employee_with_data")
  @browser.element(class: /interaction-click-control-create-employee/).click
end

And(/^I should see employer census family created success message$/) do
  Watir::Wait.until(30) {  @browser.text.include?("Census Employee is successfully created.") }
  screenshot("employer_census_new_family_success_message")
  @browser.refresh
  @browser.a(text: /Employees/).wait_until_present
  @browser.a(text: /Employees/).click
  @browser.a(text: /John K Doe Jr/).wait_until_present
  expect(@browser.a(text: /John K Doe Jr/).visible?).to be_truthy
  expect(@browser.a(text: /Edit/).visible?).to be_truthy
  expect(@browser.a(text: /Terminate/).visible?).to be_truthy
  expect(@browser.a(text: /Delink/).visible?).to be_truthy
end

When(/^I click on Edit family button for a census family$/) do
  @browser.a(text: /Edit/).wait_until_present
  @browser.a(text: /Edit/).click
end

Then(/^I should see a form to update the contents of the census employee$/) do
  @browser.button(value: /Update Employee/).wait_until_present
  @browser.text_field(id: /census_employee_first_name/).set("Patrick")
  @browser.text_field(id: /census_employee_address_attributes_state/).set("VA")
  screenshot("update_census_employee_with_data")
  @browser.button(value: /Update Employee/).click
end

And(/^I should see employer census family updated success message$/) do
  Watir::Wait.until(30) {  @browser.text.include?("Census Employee is successfully updated.") }
end

And(/^I logout from employer portal$/) do
  @browser.goto("http://localhost:3000/")
  @browser.a(text: /Logout/).wait_until_present
  @browser.a(text: /Logout/).click
end


When(/^I click on terminate button for a census family$/) do
  ce = Organization.where(legal_name: 'Turner Agency, Inc').first.employer_profile.census_employees.first.dup
  ce.save
  @browser.a(text: /Terminate/).wait_until_present
  @browser.a(text: /Terminate/).click
  terminated_date = Date.current + 20.days
  @browser.text_field(class: /date-picker/).set(terminated_date)
  #click submit
  @browser.h3(text: /Employee Roster/).click
  @browser.a(text: /Submit/).wait_until_present
  @browser.a(text: /Submit/).click
end

Then(/^The census family should be terminated and move to terminated tab$/) do
  @browser.a(text: /Employees/).wait_until_present
  @browser.a(text: /Employees/).click
  @browser.radio(id: "terminated_yes").fire_event("onclick")
  @browser.a(text: /Patrick K Doe Jr/).wait_until_present
  expect(@browser.a(text: /Patrick K Doe Jr/).visible?).to be_truthy
  @browser.a(text: /Employees/).wait_until_present
  @browser.a(text: /Employees/).click
  expect(@browser.a(class: /interaction-click-control-rehire/).visible?).to be_truthy
  #expect(@browser.a(text: /Rehire/).visible?).to be_truthy
end

And(/^I should see the census family is successfully terminated message$/) do
  Watir::Wait.until(30) {  @browser.text.include?("Successfully terminated family.") }
end

When(/^I click on Rehire button for a census family on terminated tab$/) do
  @browser.a(text: /Rehire/).wait_until_present
  @browser.a(text: /Rehire/).click
end

Then(/^A new instance of the census family should be created$/) do
  @browser.radio(id: "terminated_no").wait_until_present
  @browser.radio(id: "terminated_no").fire_event("onclick")
  @browser.a(text: /Terminate/).wait_until_present
  expect(@browser.text.include?(/Patrick K Doe Jr/)).to be_truthy
  expect(@browser.a(text: /Terminate/).visible?).to be_truthy
end

And(/^I should see the census family is successfully rehired message$/) do
  Watir::Wait.until(30) {  @browser.text.include?("Successfully rehired family.") }
end


When(/^I go to the benefits tab I should see plan year information$/) do
  @browser.a(text: /Benefits/).wait_until_present
  @browser.a(text: /Benefits/).click
end


And(/^I should see a button to create new plan year$/) do
  @browser.a(text: /Add Plan Year/).wait_until_present
  screenshot("employer_plan_year")
  @browser.a(text: /Add Plan Year/).click
end

And(/^I should be able to add information about plan year, benefits and relationship benefits$/) do
#Plan Year
  @browser.text_field(class: "interaction-field-control-plan_year-start_on").wait_until_present
  screenshot("employer_add_plan_year")
  # validation error path
  @browser.text_field(class: "interaction-field-control-plan_year-start_on").set("01/06/2017")
  @browser.h3(text: /Plan Year/).click
  sleep(1)
  @browser.h4(text: /start on must be first day of the month/).wait_until_present
  expect(@browser.text.include?("start on must be first day of the month")).to be_truthy
  # happy path
  begin_date = (Date.current + 1.year).beginning_of_year
  @browser.text_field(class: "interaction-field-control-plan_year-start_on").set(begin_date)
  @browser.h3(text: /Plan Year/).click
  sleep(1)
  @browser.h4(text: /Recommend Date/).wait_until_present
  expect(@browser.text.include?("employer initial application earliest submit on")).to be_truthy
  @browser.text_field(name: "plan_year[fte_count]").click
  @browser.text_field(name: "plan_year[fte_count]").set("35")
  @browser.text_field(name: "plan_year[pte_count]").set("15")
  @browser.text_field(name: "plan_year[msp_count]").set("3")
  # Benefit Group
  @browser.text_field(name: "plan_year[benefit_groups_attributes][0][title]").set("Silver PPO Group")
  @browser.text_field(name: "plan_year[benefit_groups_attributes][0][employer_max_amt_in_cents]").set(1245)
  elected_field = @browser.div(class: /selectric-wrapper/, text: /A single plan/)
  elected_field.click
  elected_field.li(text: /All plans from a given carrier/).click
  input_field = @browser.div(class: /selectric-wrapper/, text: /SELECT CARRIER/)
  input_field.click
  input_field.li(text: /CareFirst/).click
  ref_plan = @browser.divs(class: /selectric-wrapper/, text: /SELECT REFERENCE PLAN/).last
  ref_plan.click
  ref_plan.li(index: 5).click # select plan from list.
  # Relationship Benefit
  @browser.text_field(name: "plan_year[benefit_groups_attributes][0][relationship_benefits_attributes][0][premium_pct]").set(21)
  @browser.checkboxes(id: 'plan_year_benefit_groups_attributes_0_relationship_benefits_attributes_0_offered').first.set(true)
  @browser.text_field(name: "plan_year[benefit_groups_attributes][0][relationship_benefits_attributes][3][premium_pct]").set(15)
  @browser.checkboxes(id: 'plan_year_benefit_groups_attributes_0_relationship_benefits_attributes_3_offered').first.set(true)
  @browser.checkboxes(id: 'plan_year_benefit_groups_attributes_0_relationship_benefits_attributes_1_offered').first.set(false)
  @browser.checkboxes(id: 'plan_year_benefit_groups_attributes_0_relationship_benefits_attributes_2_offered').first.set(false)
  @browser.checkboxes(id: 'plan_year_benefit_groups_attributes_0_relationship_benefits_attributes_4_offered').first.set(false)
  @browser.checkboxes(id: 'plan_year_benefit_groups_attributes_0_relationship_benefits_attributes_5_offered').first.set(false)
  screenshot("employer_add_plan_year_info")
  @browser.button(value: /Create Plan Year/).click
end

And(/^I should see a success message after clicking on create plan year button$/) do
  Watir::Wait.until(30) {  @browser.text.include?("Plan Year successfully created.") }
  screenshot("employer_plan_year_success_message")
  Organization.where(legal_name: 'Turner Agency, Inc').first.employer_profile.plan_years.first.update(start_on: '2015-01-01', end_on: '2015-12-31', open_enrollment_start_on: '2014-01-01', open_enrollment_end_on: '2014-11-30')
end

When(/^I enter filter in plan selection page$/) do
  Watir::Wait.until(30) { @browser.a(text: /All Filters/).present? }
  @browser.a(text: /All Filters/).wait_until_present
  @browser.a(text: /All Filters/).click
  @browser.checkboxes(class: /plan-type-selection-filter/).first.set(true)
  @browser.button(class: /apply-btn/, text: /Apply/).wait_until_present
  @browser.button(class: /apply-btn/, text: /Apply/).click
end

When(/^I enter combined filter in plan selection page$/) do
  @browser.a(text: /All Filters/).wait_until_present
  @browser.a(text: /All Filters/).click
  @browser.checkboxes(class: /plan-type-selection-filter/).first.wait_until_present
  @browser.checkboxes(class: /plan-type-selection-filter/).first.set(false)
  # Nationwide
  @browser.checkboxes(class: /plan-metal-network-selection-filter/).first.set(true)
  # Platinum
  @browser.checkboxes(class: /plan-metal-level-selection-filter/)[0].set(true)
  @browser.text_field(class: /plan-metal-deductible-from-selection-filter/).set("")
  @browser.text_field(class: /plan-metal-deductible-to-selection-filter/).set("")
  @browser.text_field(class: /plan-metal-premium-from-selection-filter/).set("$420")
  @browser.text_field(class: /plan-metal-premium-to-selection-filter/).set("$430")
  @browser.button(class: /apply-btn/, text: /Apply/).click
end

Then(/^I should see the combined filter results$/) do
  @browser.divs(class: /plan-row/).select(&:visible?).each do |plan|
    expect(plan.text.include?("Nationwide")).to eq true
    expect(plan.text.include?("Bronze")).to eq true
    expect(plan.p(text: "$425.66").visible?).to eq true
  end
end
