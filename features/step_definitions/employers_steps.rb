Then(/^.+ should see a welcome page with successful sign in message$/) do
  Watir::Wait.until(30) { @browser.text.include?(/Signed in successfully./) }
  screenshot("employer_portal_sign_in_welcome")
  expect(@browser.text.include?("Signed in successfully.")).to be_truthy
  @browser.a(text: /Continue/).wait_until_present
  expect(@browser.a(text: /Continue/).visible?).to be_truthy
  @browser.a(text: /Continue/).click
end

Then(/^.+ should see fields to search for person and employer$/) do
  Watir::Wait.until(30) { @browser.text.include?(/Personal Information/) }
  screenshot("employer_portal_person_search")
  expect(@browser.text.include?(/Personal Information/)).to be_truthy
end

Then(/^.+ should see an initial fieldset to enter my name, ssn and dob$/) do
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

And(/^.+ should see a form with a fieldset for Employer information, including: legal name, DBA, fein, entity_kind, broker agency, URL, address, and phone$/) do
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

When(/^.+ click on an employer in the employer list$/) do
  @browser.a(text: /True First Inc/).wait_until_present
  @browser.a(text: /True First Inc/).click
end

Then(/^.+ should see the employer information$/) do
  @browser.text.include?("True First Inc").wait_until_present
  expect(@browser.text.include?("True First Inc")).to be_truthy
  expect(@browser.text.include?("13101 elm tree dr\nxyz\nDunwoody, GA 30027\n(303) 123-0981 x 1231")).to be_truthy
  expect(@browser.text.include?("Enrollment\nNo Plan Years Found")).to be_truthy
end

Then(/^.+ should see the employee family roster$/) do
  @browser.a(class: /interaction-click-control-add-new-employee/).wait_until_present
  screenshot("employer_census_family")
  expect(@browser.a(class: /interaction-click-control-add-new-employee/).visible?).to be_truthy
  @browser.a(class: /interaction-click-control-add-new-employee/).click
end


Then(/^.+ should see a form to enter information about employee, address and dependents details$/) do

  # Census Employee
  @browser.text_field(class: /interaction-field-control-census-employee-first-name/).wait_until_present
  @browser.text_field(class: /interaction-field-control-census-employee-first-name/).set("John")
  @browser.text_field(class: /interaction-field-control-census-employee-middle-name/).set("K")
  @browser.text_field(class: /interaction-field-control-census-employee-last-name/).set("Doe")
  @browser.p(text: /suffix/i).click
  suffix = @browser.element(class: /selectric-scroll/)
  suffix.wait_until_present
  suffix = @browser.element(class: /selectric-scroll/)
  suffix.li(text: /Jr./).click
  @browser.h1(text: /Add New Employee/i).click

  # @browser.text_field(class: /interaction-field-control-census-employee-dob/).set("01/01/1980")
  @browser.text_field(class: /interaction-field-control-jq-datepicker-ignore-census-employee-dob/).set("01/01/1980")
  @browser.text_field(class: /interaction-field-control-census-employee-ssn/).set("786120965")
  #@browser.radio(class: /interaction-choice-control-value-radio-male/).set
  @browser.radio(id: /radio_male/).fire_event("onclick")
  @browser.text_field(class: /interaction-field-control-jq-datepicker-ignore-census-employee-hired-on/).set("10/10/2014")
  @browser.checkbox(class: /interaction-choice-control-value-census-employee-is-business-owner/).set
  @browser.p(text: /Silver PPO Group/i).click
  @browser.li(text: /Silver PPO Group/).click

  # Address
  @browser.text_field(class: /interaction-field-control-census-employee-address-attributes-address-1/).wait_until_present
  @browser.text_field(class: /interaction-field-control-census-employee-address-attributes-address-1/).set("1026 Potomac")
  @browser.text_field(class: /interaction-field-control-census-employee-address-attributes-address-2/).set("apt abc")
  @browser.text_field(class: /interaction-field-control-census-employee-address-attributes-city/).set("Alpharetta")
  select_state = @browser.divs(text: /SELECT STATE/).last
  select_state.click
  scroll_then_click(@browser.li(text: /GA/))
  @browser.text_field(class: /interaction-field-control-census-employee-address-attributes-zip/).set("30228")
  email_kind = @browser.divs(text: /SELECT KIND/).last
  email_kind.click
  @browser.li(text: /home/).click
  @browser.text_field(class: /interaction-field-control-census-employee-email-attributes-address/).set("trey.john@dc.gov")

  @browser.a(text: /Add Family Member/).click
  @browser.div(id: /dependent_info/).wait_until_present
  @browser.text_field(id: /census_employee_census_dependents_attributes_\d+_first_name/).set("Mary")
  @browser.text_field(id: /census_employee_census_dependents_attributes_\d+_middle_name/).set("K")
  @browser.text_field(id: /census_employee_census_dependents_attributes_\d+_last_name/).set("Doe")
  @browser.text_field(id: /jq_datepicker_ignore_census_employee_census_dependents_attributes_\d+_dob/).set("10/12/2012")
  @browser.text_field(id: /census_employee_census_dependents_attributes_\d+_ssn/).set("321321321")
  @browser.label(for: /census_employee_census_dependents_attributes_\d+_gender_female/).click
  input_field = @browser.divs(class: "selectric-wrapper").last
  input_field.click
  input_field.li(text: /Child/).click

  screenshot("create_census_employee_with_data")
  @browser.element(class: /interaction-click-control-create-employee/).click
end

And(/^.+ should see employer census family created success message$/) do
  sleep(1)
  expect(@browser.div(text: /successfully/).visible?).to be_truthy
  screenshot("employer_census_new_family_success_message")
  @browser.refresh
  @browser.a(text: /Employees/).wait_until_present
  @browser.a(text: /Employees/).click
  @browser.a(text: /John K Doe Jr/).wait_until_present
  expect(@browser.a(text: /John K Doe Jr/).visible?).to be_truthy
end

When(/^.+ clicks? on Edit family button for a census family$/) do
  @browser.a(text: /employees/i).wait_until_present
  @browser.a(text: /employees/i).click
  @browser.a(class: /interaction-click-control-add-new-employee/).wait_until_present
  @browser.i(class: /fa-pencil/).fire_event("onclick")
end

When(/^.+ edits? ssn and dob on employee detail page after linked$/) do
  Organization.where(legal_name: 'Turner Agency, Inc').first.employer_profile.census_employees.first.link_employee_role!

  @browser.button(value: /Update Employee/).wait_until_present
  @browser.text_field(id: /jq_datepicker_ignore_census_employee_dob/).set("01/01/1981")
  @browser.text_field(id: /census_employee_ssn/).set("786120969")
  @browser.button(value: /Update Employee/).wait_until_present
  @browser.button(value: /Update Employee/).click
end


Then(/^.+ should see Access Denied$/) do
  @browser.element(text: /Access Denied!/).wait_until_present
  @browser.element(text: /Access Denied!/).visible?
end

When(/^.+ go back$/) do
  @browser.execute_script('window.history.back()')
end

Then(/^.+ should see a form to update the contents of the census employee$/) do
  #Organization.where(legal_name: 'Turner Agency, Inc').first.employer_profile.census_employees.first.delink_employee_role!

  @browser.button(text: /Update Employee/i).wait_until_present
  @browser.text_field(id: /census_employee_first_name/).set("Patrick")
  @browser.text_field(id: /jq_datepicker_ignore_census_employee_dob/).set("01/01/1980")
  @browser.text_field(id: /census_employee_ssn/).set("786120965")
  @browser.p(text: /Silver PPO Group/i).click
  @browser.li(text: /Silver PPO Group/).click
  select_state = @browser.divs(text: /GA/).last
  select_state.click
  scroll_then_click(@browser.li(text: /VA/))
  #@browser.text_field(id: /census_employee_address_attributes_state/).set("VA")
  @browser.text_field(id: /census_employee_census_dependents_attributes_\d+_first_name/).set("Mariah")
  @browser.checkbox(id: /census_employee_is_business_owner/i).fire_event("onclick")
  input_field = @browser.divs(class: "selectric-wrapper").last
  input_field.click
  input_field.li(text: /Child/).click
  screenshot("update_census_employee_with_data")
  @browser.button(text: /Update Employee/i).fire_event('onclick')
end

And(/^.+ should see employer census family updated success message$/) do
  @browser.element(class: /interaction-click-control-add-new-employee/).wait_until_present
  Watir::Wait.until(30) {  @browser.text.include?("Census Employee is successfully updated.") }
end

When(/^.+ clicks on terminate button for a census family$/) do
  # ce = Organization.where(legal_name: 'Turner Agency, Inc').first.employer_profile.census_employees.first.dup
  # ce.save
  @browser.a(text: /Terminate/).wait_until_present
  @browser.a(text: /Terminate/).click
  terminated_date = TimeKeeper.date_of_record + 20.days
  @browser.text_field(class: /date-picker/).set(terminated_date)
  #click submit
  @browser.h3(text: /Employee Roster/).click
  @browser.a(text: /Submit/).wait_until_present
  @browser.a(text: /Submit/).click
end

When(/^.+ clicks on terminate button for rehired census employee$/) do
  @browser.a(text: /Terminate/).wait_until_present
  @browser.execute_script("$('.interaction-click-control-terminate').last().trigger('click')")
  terminated_date = (TimeKeeper.date_of_record + 60.days).strftime("%m/%d/%Y")
  @browser.execute_script("$('.date-picker').val(\'#{terminated_date}\')")
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
  @browser.td(text: /Employment terminated/).wait_until_present
  expect(@browser.td(text: /Employment terminated/).visible?).to be_truthy
  #@browser.a(text: /Rehire/).wait_until_present
end

And(/^.+ should see the census family is successfully terminated message$/) do
  Watir::Wait.until(30) {  @browser.text.include?("Successfully terminated family.") }
end

When(/^.+ clicks? on Rehire button for a census family on terminated tab$/) do
  # Organization.where(legal_name: 'Turner Agency, Inc').first.employer_profile.census_employees.where(aasm_state: "employment_terminated").update(name_sfx: "Sr", first_name: "Polly")
  @browser.a(text: /Rehire/).wait_until_present
  @browser.a(text: /Rehire/).click
  hired_date = (TimeKeeper.date_of_record + 30.days).strftime("%m/%d/%Y")
  #@browser.text_field(class: /hasDatepicker/).set(hired_date)
  @browser.execute_script("$('.date-picker').val(\'#{hired_date}\')")
  #click submit
  @browser.h3(text: /Employee Roster/).click
  @browser.a(text: /Submit/).wait_until_present
  @browser.a(text: /Submit/).click
end

Then(/^A new instance of the census family should be created$/) do
  @browser.a(text: /Employees/).wait_until_present
  @browser.a(text: /Employees/).click
  @browser.radio(id: "family_all").wait_until_present
  @browser.radio(id: "family_all").fire_event("onclick")
  @browser.element(text: /Rehired/).wait_until_present
  @browser.element(text: /Rehired/).visible?
  expect(@browser.a(text: /Terminate/).visible?).to be_truthy
end

And(/^.+ should see the census family is successfully rehired message$/) do
  Watir::Wait.until(30) {  @browser.text.include?("Successfully rehired family.") }
end

When(/^I go to the Profile tab$/) do
  @browser.a(class: /interaction-click-control-update-business-info/).wait_until_present
  @browser.a(class: /interaction-click-control-update-business-info/).click
  @browser.a(class: /interaction-click-control-cancel/).wait_until_present
  @browser.a(class: /interaction-click-control-cancel/).click
  @browser.a(text: /business info/i).wait_until_present
  expect(@browser.a(text: /Business Info/i).visible?).to be_truthy
end


When(/^.+ go[es]+ to the benefits tab I should see plan year information$/) do
  @browser.a(text: /Benefits/).wait_until_present
  @browser.a(text: /Benefits/).click
end


And(/^.+ should see a button to create new plan year$/) do
  @browser.a(class: /interaction-click-control-add-plan-year/).wait_until_present
  screenshot("employer_plan_year")
  @browser.a(class: /interaction-click-control-add-plan-year/).click
end

And(/^.+ should be able to enter plan year, benefits, relationship benefits with high FTE$/) do
#Plan Year
  # @browser.text_field(id: "jq_datepicker_ignore_plan_year_open_enrollment_start_on").wait_until_present
  # @browser.text_field(id: /plan_year_fte_count/).wait_until_present
  @browser.div(class: /selectric-interaction-choice-control-plan-year-start-on/).wait_until_present
  start_on = @browser.div(class: /selectric-interaction-choice-control-plan-year-start-on/)
  start_on.fire_event('onclick')
  start_on.li(index: 1).fire_event('onclick')
  screenshot("employer_add_plan_year")
  # @browser.text_field(id: "jq_datepicker_ignore_plan_year_open_enrollment_start_on").set("91/96/2017")
  # @browser.h3(text: /Plan Year/).click
  # @browser.alert.wait_until_present
  # @browser.alert.ok
  # expect(@browser.text.include?("Open Enrollment Start Date: Invalid date format!")).to be_truthy
  # happy path
  # start_on_field = @browser.div(class: /selectric-wrapper/, text: /SELECT START ON/i)
  # start_on_field.click
  # start_on_field.li(index: 1).click
  @browser.text_field(name: "plan_year[fte_count]").fire_event('onclick')
  @browser.text_field(name: "plan_year[fte_count]").set("235")
  @browser.text_field(name: "plan_year[pte_count]").set("15")
  @browser.text_field(name: "plan_year[msp_count]").set("3")
  @browser.a(class: /interaction-click-control-continue/).wait_until_present
  @browser.a(class: /interaction-click-control-continue/).fire_event('onclick')


  # Benefit Group

  @browser.text_field(name: "plan_year[benefit_groups_attributes][0][title]").set("Silver PPO Group")
  select_field = @browser.div(class: /selectric-wrapper/, text: /Date Of Hire/)
  select_field.click
  select_field.li(text: /Date of hire/i).click
  @browser.text_field(name: "plan_year[benefit_groups_attributes][0][relationship_benefits_attributes][0][premium_pct]").set(50)
  @browser.text_field(name: "plan_year[benefit_groups_attributes][0][relationship_benefits_attributes][1][premium_pct]").set(50)
  @browser.text_field(name: "plan_year[benefit_groups_attributes][0][relationship_benefits_attributes][2][premium_pct]").set(50)
  @browser.text_field(name: "plan_year[benefit_groups_attributes][0][relationship_benefits_attributes][3][premium_pct]").set(50)
  select_plan_option = @browser.ul(class: /nav-tabs/)
  select_plan_option.li(text: /By carrier/i).click
  carriers_tab = @browser.div(class: /carriers-tab/)
  sleep(3)
  carriers_tab.as[1].fire_event("onclick")
  plans_tab = @browser.div(class: /reference-plans/)
  sleep(3)
  plans_tab.labels.last.fire_event('onclick')
  sleep(3)
  # @browser.a(class: /add_fields/).fire_event('onclick')
  # sleep(3)
  # benefit_groups = @browser.fieldsets(class: /benefit-group-fields/)
  # benefit_groups.last.text_fields.first.set("Gold HMO")
  # @browser.text_fields(name: /relationship_benefits_attributes/).set(55)

  @browser.button(class: /interaction-click-control-create-plan-year/).fire_event("onclick")
end

And(/^.+ should see a success message after clicking on create plan year button$/) do
  @browser.element(text: /Plan Year successfully created/).wait_until_present
  screenshot("employer_plan_year_success_message")
end

When(/^.+ enters filter in plan selection page$/) do
  @browser.element(text: /Filter Results/).wait_until_present
  @browser.checkboxes(class: /plan-type-selection-filter/).first.set(true)
  @browser.element(class: /apply-btn/, text: /Apply/i).wait_until_present
  scroll_then_click(@browser.element(class: /apply-btn/, text: /Apply/i))
end

When(/^.+ enters? hsa_compatible filter in plan selection page$/) do
  select_carrier = @browser.div(class: /selectric-plan-carrier-selection-filter/)
  click_when_present(select_carrier)
  select_carrier.li(text: /CareFirst/).click
  select_hsa = @browser.div(class: /selectric-plan-hsa-eligibility-selection-filter/)
  click_when_present(select_hsa)
  select_hsa.li(text: /All/i).click
  scroll_into_view(@browser.checkboxes(class: /plan-metal-level-selection-filter/)[1])
  @browser.checkboxes(class: /plan-metal-level-selection-filter/)[1].set(true)
  @browser.text_field(class: /plan-metal-deductible-from-selection-filter/).set("2000")
  scroll_then_click(@browser.element(class: /apply-btn/, text: /Apply/i))
end

When(/^.+ enters? combined filter in plan selection page$/) do
  #@browser.a(text: /All Filters/).wait_until_present
  #@browser.a(text: /All Filters/).click
  # @browser.checkboxes(class: /plan-type-selection-filter/).first.wait_until_present
  # @browser.checkboxes(class: /plan-type-selection-filter/).first.set(false)
  # Nationwide
  # @browser.checkboxes(class: /plan-metal-network-selection-filter/).first.set(true)
  #@browser.checkbox(class: /checkbox-custom interaction-choice-control-value-checkbox-5/).set(true)

  # Platinum
  @browser.execute_script(
    'arguments[0].scrollIntoView();',
    @browser.element(:text => /Choose Plan/i)
  )
  @browser.checkbox(class: /interaction-choice-control-value-plan-metal-level-silver/).set(true)
  @browser.checkboxes(class: /plan-type-selection-filter/).first.set(false)
  @browser.checkboxes(class: /plan-type-selection-filter/).last.set(true)
  @browser.text_field(class: /plan-metal-deductible-from-selection-filter/).set("1000")
  @browser.text_field(class: /plan-metal-deductible-to-selection-filter/).set("5500")
  @browser.text_field(class: /plan-metal-premium-from-selection-filter/).set("5")
  @browser.text_field(class: /plan-metal-premium-to-selection-filter/).set("250")
  @browser.element(class: /apply-btn/, text: /Apply/i).click
end

Then(/^.+ should see the hsa_compatible filter results$/) do
  @browser.divs(class: /plan-row/).select(&:visible?).first do |plan|
    expect(plan.text.include?("BlueChoice Plus $2000")).to eq true
    expect(plan.text.include?("Silver")).to eq true
    expect(plan.element(text: "$237.15").visible?).to eq true
  end
end

Then(/^.+ should see the combined filter results$/) do
  @browser.divs(class: /plan-row/).select(&:visible?).first do |plan|
    expect(plan.text.include?("BlueChoice Plus HSA/HRA $3500")).to eq true
    expect(plan.text.include?("Bronze")).to eq true
    expect(plan.element(text: "$126.18").visible?).to eq true
  end
end

When(/^.+ go(?:es)? to the benefits tab$/) do
  @browser.element(class: /interaction-click-control-benefits/).wait_until_present
  @browser.element(class: /interaction-click-control-benefits/).click
end

Then(/^.+ should see the plan year$/) do
  @browser.element(class: /interaction-click-control-publish-plan-year/).wait_until_present
end

When(/^.+ clicks? on publish plan year$/) do
  @browser.element(class: /interaction-click-control-publish-plan-year/).wait_until_present
  @browser.element(class: /interaction-click-control-publish-plan-year/).click
end

Then(/^.+ should see Publish Plan Year Modal with warnings$/) do

  @browser.element(class: /modal-body/).wait_until_present

  modal = @browser.div(class: /modal-dialog/)
  warnings= modal.ul(class: /application-warnings/)
  # TODO:  Add visible? to the next line.  This test is not valid.
  expect(warnings.element(text: /number of full time equivalents (FTEs) exceeds maximum allowed/i)).to be_truthy
end

Then(/^.+ clicks? on the Cancel button$/) do
  modal = @browser.div(class: 'modal-dialog')
  modal.a(class: 'interaction-click-control-cancel').click
end

Then(/^.+ should be on the Plan Year Edit page with warnings$/) do
  @browser.element(id: /plan_year/).present?
  warnings= @browser.div(class: 'alert-plan-year')
  # TODO:  Add visible? to the next line.  This test is not valid.
  expect(warnings.element(text: /number of full time equivalents (FTEs) exceeds maximum allowed/i)).to be_truthy
end

Then(/^.+ updates? the FTE field with valid input and save plan year$/) do
  @browser.button(class: /interaction-click-control-save-plan-year/).wait_until_present
  @browser.text_field(name: "plan_year[fte_count]").set("10")
  scroll_then_click(@browser.button(class: /interaction-click-control-save-plan-year/))
end

Then(/^.+ should see a plan year successfully saved message$/) do
  @browser.element( text: /Benefits - Coverage you offer/i).wait_until_present
  # TODO:  Add visible? to the next line.  This test is not valid.
  expect(@browser.element(text: /Plan Year successfully saved/)).to be_truthy
end
