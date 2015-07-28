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
  scroll_then_click(@browser.element(class: /interaction-click-control-create-broker-agency/))
end


Then(/^I should see broker registration successful message$/) do
  @browser.element(text: /Your registration has been submitted. A response will be sent to the email address you provided once your application is reviewed./).wait_until_present
  expect(@browser.element(text: /Your registration has been submitted. A response will be sent to the email address you provided once your application is reviewed./).visible?).to be_truthy
end


When(/^I login as an Hbx Admin$/) do
  @browser.goto("http://localhost:3000/")
  @browser.a(class: /interaction-click-control-hbx-portal/).wait_until_present
  @browser.a(class: /interaction-click-control-hbx-portal/).click
  @browser.element(class: /interaction-click-control-sign-in/).wait_until_present
  @browser.text_field(class: /interaction-field-control-user-email/).set("admin@dc.gov")
  @browser.text_field(class: /interaction-field-control-user-password/).set("password")
  @browser.element(class: /interaction-click-control-sign-in/).click
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

When(/^I click on Browse Borkers button$/) do
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









