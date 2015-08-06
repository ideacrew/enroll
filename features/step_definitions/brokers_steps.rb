When(/^I visit the HBX Broker Registration form$/) do
  @browser.goto("http://localhost:3000/")
  @browser.element(class: /interaction-click-control-broker-registration/).wait_until_present
  @browser.element(class: /interaction-click-control-broker-registration/).click
end

When(/^I click on New Broker Agency Tab$/) do 
  @browser.radio(class: /interaction-choice-control-value-new-broker-agency/).wait_until_present
  @browser.radio(class: /interaction-choice-control-value-new-broker-agency/).fire_event("onclick")
end

When(/^I should see the New Broker Agency form$/) do
  @browser.element(id: "broker_agency_form").wait_until_present
  expect(@browser.element(id: "broker_agency_form").visible?).to be_truthy
end

When(/^I enter personal information$/) do
  @browser.text_field(class: /interaction-field-control-person-first-name/).set("Ricky")
  @browser.text_field(class: /interaction-field-control-person-last-name/).set("Martin")
  @browser.text_field(class: /interaction-field-control-person-dob/).set("10/10/1984")
  @browser.text_field(class: /interaction-field-control-person-email/).click
  @browser.text_field(class: /interaction-field-control-person-email/).set("ricky.martin@example.com")
  @browser.text_field(class: /interaction-field-control-person-npn/).set("109109109")
end

And(/^I enter broker agency information$/) do
  @browser.text_field(class: /interaction-field-control-organization-legal-name/).set("Logistics Inc")
  @browser.text_field(class: /interaction-field-control-organization-dba/).set("Logistics Inc")
  @browser.text_field(class: /interaction-field-control-organization-fein/).set("890890891")
  
  entity_kind = @browser.div(class: /interaction-choice-control-organization-entity-kind/)
  entity_kind.click
  entity_kind.li(text: /S Corporation/).click

  @browser.text_field(class: /interaction-field-control-broker-corporate-npn/).set("890890892")
  @browser.text_field(class: /interaction-field-control-broker-home-page/).set("www.logistics.example.com")

  practice_area = @browser.div(class: /selectric-interaction-choice-control-broker-agency-practice-area/)
  practice_area.click
  practice_area.li(text: /Small Business Marketplace ONLY/).click

  language_multi_select = @browser.element(class: "language_multi_select").element(class: "multiselect")
  language_multi_select.wait_until_present
  language_multi_select.click
  @browser.checkbox(:value => 'bn').set
  @browser.checkbox(:value => 'fr').set
  
  @browser.checkbox(:name => "organization[working_hours]").set
  @browser.checkbox(:name => "organization[accept_new_clients]").set
end

And(/^I enter office locations information$/) do
  enter_office_location({
    address1: "623a Spalding Ct",
    address2: "Suite 200",
    city: "McLean",
    state: "VA",
    zip: "22180",
    phone_area_code: "202",
    phone_number: "1110000",
    phone_extension: "1111"
    })
end


And(/^I click on Create Broker Agency$/) do
  @browser.element(class: /interaction-click-control-create-broker-agency/).wait_until_present
  scroll_then_click(@browser.button(class: /interaction-click-control-create-broker-agency/))
end


Then(/^I should see broker registration successful message$/) do
  @browser.element(text: /Your registration has been submitted. A response will be sent to the email address you provided once your application is reviewed./).wait_until_present
  expect(@browser.element(text: /Your registration has been submitted. A response will be sent to the email address you provided once your application is reviewed./).visible?).to be_truthy
end

And(/^I click on brokers tab$/) do
  @browser.element(class: /interaction-click-control-brokers/).wait_until_present
  scroll_then_click(@browser.element(class: /interaction-click-control-brokers/))
end

And(/^I should see the list of broker applicants$/) do
end

Then(/^I click on the current broker applicant show button$/) do
  @browser.element(class: /interaction-click-control-broker-show/).wait_until_present
  scroll_then_click(@browser.element(class: /interaction-click-control-broker-show/))
end

And(/^I should see the broker application$/) do
end

And(/^I click on approve broker button$/) do
  @browser.element(class: /interaction-click-control-broker-approve/).wait_until_present
  scroll_then_click(@browser.element(class: /interaction-click-control-broker-approve/))
end

Then(/^I should see the broker successfully approved message$/) do
  @browser.element(text: /Broker applicant approved successfully./).wait_until_present
  expect(@browser.element(text: /Broker applicant approved successfully./).visible?).to be_truthy
end

And(/^I should receive an invitation email$/) do
  open_email("ricky.martin@example.com")
  expect(current_email.to).to eq(["ricky.martin@example.com"])
  current_email.should have_subject('DCHealthLink Invitation ')
end

When(/^I visit invitation url in email$/) do
  invitation_link = links_in_email(current_email).first
  invitation_link.sub!(/https\:\/\/enroll1\.dchealthlink\.com/, 'http://localhost:3000')
  @browser.goto(invitation_link)
end

Then(/^I should see the login page$/) do
  @browser.element(class: /interaction-click-control-sign-in/).wait_until_present
end

When(/^I click on Create Account$/) do
  @browser.a(text: /Create account/).wait_until_present
  @browser.a(text: /Create account/).click
end

When(/^I register with valid information$/) do
  @browser.text_field(name: "user[password_confirmation]").wait_until_present
  @browser.text_field(name: "user[email]").set("ricky.martin@example.com")
  @browser.text_field(name: "user[password]").set("12345678")
  @browser.text_field(name: "user[password_confirmation]").set("12345678")
  @browser.input(value: /Create account/).click
end

Then(/^I should see successful message with broker agency home page$/) do
  @browser.element(text: /Welcome! Your account has been created./).wait_until_present
  expect(@browser.element(text: /Welcome! Your account has been created./).visible?).to be_truthy

  @browser.h3(text: /Broker Agency \: Logistics Inc/).wait_until_present
  expect(@browser.h3(text: /Broker Agency \: Logistics Inc/).visible?).to be_truthy
end

When(/^I click on the Broker Agency tab$/) do
  @browser.a(text: /Broker Agency/).wait_until_present
  scroll_then_click(@browser.a(text: /Broker Agency/))
end

Then(/^I should see no active broker$/) do
  @browser.element(text: /No Active Broker/).wait_until_present
  expect(@browser.element(text: /No Active Broker/).visible?).to be_truthy
end

When(/^I click on Browse Brokers button$/) do
  @browser.a(text: /Browse Brokers/).wait_until_present
  @browser.a(text: /Browse Brokers/).click
end

Then(/^I should see broker agencies index view$/) do
  @browser.h4(text: /Broker Agencies/).wait_until_present
  expect(@browser.h4(text: /Broker Agencies/).visible?).to be_truthy
end

When(/^I search broker agency by name$/) do
  search_div = @browser.div(class: "broker_agencies_search")
  search_div.wait_until_present

  search_div.text_field(name: "q").wait_until_present
  search_div.text_field(name: "q").set("Logistics")

  search_div.button(class: /btn/).wait_until_present
  search_div.button(class: /btn/).click
end

Then(/^I should see broker agency$/) do
  @browser.a(text: /Logistics Inc/).wait_until_present
  expect(@browser.a(text: /Logistics Inc/).visible?).to be_truthy
end

Then(/^I click select broker button$/) do
  @browser.a(text: /Select Broker/).wait_until_present
  @browser.a(text: /Select Broker/).click
end

Then(/^I should see confirm modal dialog box$/) do
  @browser.element(class: /modal-dialog/).wait_until_present
  expect(@browser.div(class: /modal-body/).p(text: /Click Confirm to hire the selected broker\. Warning\: if you have an existing broker\,/).visible?).to be_truthy
  expect(@browser.div(class: /modal-body/).p(text: /they will be terminated effective immediately\./).visible?).to be_truthy
end

Then(/^I confirm broker selection$/) do
  modal = @browser.div(class: 'modal-dialog')
  modal.input(value: /Confirm/).wait_until_present
  modal.input(value: /Confirm/).click
end

Then(/^I should see broker selected successful message$/) do
  @browser.element(text: /Successfully associated broker with your account./).wait_until_present
  expect(@browser.element(text: /Successfully associated broker with your account./).visible?).to be_truthy
end

And (/^I should see broker active for the employer$/) do
  expect(@browser.element(text: /Logistics Inc/).visible?).to be_truthy
  expect(@browser.element(text: /Ricky Martin/).visible?).to be_truthy
end

When(/^I terminate broker$/) do
  @browser.a(text: /Terminate/).wait_until_present
  @browser.a(text: /Terminate/).click

  @browser.text_field(class: "date-picker").wait_until_present
  @browser.text_field(class: "date-picker").set("07/23/2015")

  2.times { @browser.a(text: /Terminate/).click } # To collapse calender

  @browser.a(text: /Submit/).wait_until_present
  @browser.a(text: /Submit/).click
end

Then(/^I should see broker terminated message$/) do
  @browser.element(text: /Broker terminated successfully./).wait_until_present
  expect(@browser.element(text: /Broker terminated successfully./).visible?).to be_truthy
end


And(/^I sign up as a new employer$/) do
  fill_user_registration_form({email: "tim.wood@example.com", password: "12345678"})
  @browser.input(value: /Create account/).click
end


When(/^I create new employer profile$/) do

  office_location = {
      address1: "609 H ST SW",
      address2: "Suite 200",
      city: "Washington DC",
      state: "DC",
      zip: "20005",
      phone_area_code: "202",
      phone_number: "7030000",
      phone_extension: "1000"
     }

  enter_employer_profile( {
    first_name: "Tim",
    last_name: "Wood",
    dob: "08/13/1979",
    legal_name: "Legal LLC",
    dba: "Legal LLC",
    fein: "890000223",
    office_location: office_location
  } )

  scroll_then_click(@browser.button(class: "interaction-click-control-create-employer"))
end

When(/([^ ]+) logs on to ([^ ]+)/) do |signon, portal|
  user,password = signon.split('/')
  @browser.goto("http://localhost:3000/")
  portal_class = "interaction-click-control-#{portal.downcase}"
  @browser.a(class: portal_class).wait_until_present
  @browser.a(class: portal_class).click
  @browser.element(class: /interaction-click-control-sign-in/).wait_until_present
  @browser.text_field(class: /interaction-field-control-user-email/).set(user)
  @browser.text_field(class: /interaction-field-control-user-password/).set(password)
  @browser.element(class: /interaction-click-control-sign-in/).click
end

When(/^I click on the (\w+) tab$/) do |tab_name|
  @browser.a(text: /#{tab_name}/).wait_until_present
  scroll_then_click(@browser.a(text: /#{tab_name}/))
end 

Then(/^I should see Employer and click on legal name$/) do
  @browser.a(text: /Legal LLC/).wait_until_present
  @browser.a(text: /Legal LLC/).click
end

Then(/^I should see the Employer Profile page as Broker$/) do
  wait_and_confirm_text(/Premium Billing Report/)
  expect(@browser.element(text: /I'm a Broker/).visible?).to be_truthy
end

Then(/^I publish a Plan Year as Broker$/) do
  click_when_present(@browser.element(class: /interaction-click-control-benefits/))
  click_when_present(@browser.element(class: /interaction-click-control-add-plan-year/))
  start_on = @browser.element(class: /selectric-interaction-choice-control-plan-year-start-on/)
  click_when_present(start_on)
  click_when_present(start_on.lis()[1])
  id="plan_year_benefit_groups_attributes_0_relationship_benefits_attributes_0_premium_pct"
  @browser.text_field(id: id).set(50)

  select_plan_class ="selectric-interaction-choice-control-plan-year-benefit-groups-attributes-0-plan-option-kind"
  select_plan = @browser.element(class: select_plan_class)
  click_when_present(select_plan)
  click_when_present(select_plan.lis()[3])

  f=@browser.element(class: 'form-inputs')
  benefit_form = @browser.element(class: 'form-inputs')
  select_carrier = benefit_form.element(text: 'SELECT CARRIER').parent.parent.parent
  scroll_then_click(select_carrier)
  click_when_present(select_carrier.lis()[1])
  
  sleep 3
  benefit_form.element(text: 'SELECT REFERENCE PLAN').parent.parent.parent.wait_until_present
  select_reference = benefit_form.element(text: 'SELECT REFERENCE PLAN').parent.parent.parent
  scroll_then_click(select_reference)
  benefit_form.element(text: 'SELECT REFERENCE PLAN').parent.parent.parent.lis()[1].wait_until_present
  click_when_present(select_reference.lis()[1])
  benefit_form.click
  scroll_then_click(@browser.button(class: /interaction-click-control-create-plan-year/))
  @browser.element(class: /alert-notice/, text: /Plan Year successfully created./).wait_until_present
  click_when_present(@browser.element(class: /interaction-click-control-benefits/))
  click_when_present(@browser.element(class: /interaction-click-control-publish-plan-year/))
end

When(/^I click on Employees tab$/) do
  @browser.h3(text: /Legal LLC Enrollment/).wait_until_present
  @browser.a(text: /Employees/).wait_until_present
  scroll_then_click(@browser.a(text: /Employees/))
end

Then(/^Broker clicks on the add employee button$/) do

  @browser.element(text: /Add Employee/).wait_until_present
  @browser.a(text: /Add Employee/).click
end 

Then(/^Broker creates a roster employee$/) do
  @browser.text_field(class: /interaction-field-control-census-employee-first-name/).wait_until_present
  @browser.element(class: /interaction-click-control-create-employee/).wait_until_present
  screenshot("create_census_employee")
  @browser.text_field(class: /interaction-field-control-census-employee-first-name/).set("Broker")
  @browser.text_field(class: /interaction-field-control-census-employee-last-name/).set("Assisted")
  @browser.text_field(name: "jq_datepicker_ignore_census_employee[dob]").set('05/02/1976')
  #@browser.text_field(class: /interaction-field-control-census-employee-dob/).set("01/01/1980")
  @browser.text_field(class: /interaction-field-control-census-employee-ssn/).set("761234567")
  #@browser.radio(class: /interaction-choice-control-value-radio-male/).set
  @browser.radio(id: /radio_male/).fire_event("onclick")
  @browser.text_field(name: "jq_datepicker_ignore_census_employee[hired_on]").set((Time.now-1.day).strftime('%m/%d/%Y'))
  #@browser.text_field(class: /interaction-field-control-census-employee-hired-on/).set("10/10/2014")
  @browser.checkbox(class: /interaction-choice-control-value-census-employee-is-business-owner/).set
  input_field = @browser.divs(class: /selectric-wrapper/).first
  input_field.click
  click_when_present(input_field.lis()[1])
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
  @browser.text_field(class: /interaction-field-control-census-employee-email-attributes-address/).set("broker.assist@dc.gov")
  screenshot("broker_create_census_employee_with_data")
  @browser.element(class: /interaction-click-control-create-employee/).click
end

Then(/^Broker sees employer census family created$/) do
  wait_and_confirm_text(/successfully created/)
end

Then(/^Broker Customer should see the matched employee record form$/) do
  @browser.dd(text: /Legal LLC/).wait_until_present
  screenshot("broker_employer_search_results")
  expect(@browser.dd(text: /Legal LLC/).visible?).to be_truthy
end

Then(/^Broker Assisted is a family$/) do
  wait_and_confirm_text(/Broker Assisted/)
end

Then(/^Broker goes to the Consumer page$/) do
  broker_assist_row = @browser.td(text: /Broker Assisted/).parent
  broker_assist_row.a(text: /Consumer/).click
  screenshot("broker_on_consumer_home_page")
end
Then(/^Broker is on the consumer home page$/) do
  @browser.a(class: 'interaction-click-control-shop-for-plans').wait_until_present
end

Then(/^Broker shops for plans$/) do
  @browser.a(class: 'interaction-click-control-shop-for-plans').click 
end

Then(/^Broker sees covered family members$/) do
  wait_and_confirm_text(/Covered Family Members/)
  @browser.element(id: 'btn-continue').click
end

Then(/^Broker choses a healthcare plan$/) do
  wait_and_confirm_text(/Choose a healthcare plan/)
  wait_and_confirm_text(/Apply/)
  plan = @browser.a(class: 'interaction-click-control-select-plan')
  plan.click
end

Then(/^Broker confirms plan selection$/) do
  wait_and_confirm_text(/Confirm Your Plan Selection/)
  @browser.a(text: /Purchase/).click
end

Then(/^Broker sees purchase confirmation$/) do
  wait_and_confirm_text(/Purchase confirmation/)
end

Then(/^Broker continues to the consumer home page$/) do
  wait_and_confirm_text(/Continue/)
  @browser.a(text: /Continue/).click
end