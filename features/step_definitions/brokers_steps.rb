When(/^.+ visits the HBX Broker Registration form$/) do
  @browser.goto("http://localhost:3000/")
  @browser.element(class: /interaction-click-control-broker-registration/).wait_until_present
  @browser.element(class: /interaction-click-control-broker-registration/).click
end

 When(/^Primary Broker clicks on New Broker Agency Tab$/) do 
  @browser.radio(class: /interaction-choice-control-value-new-broker-agency/).wait_until_present
  @browser.radio(class: /interaction-choice-control-value-new-broker-agency/).fire_event("onclick")
end

When(/^Primary Broker should see the New Broker Agency form$/) do
  @browser.element(id: "broker_agency_form").wait_until_present
  expect(@browser.element(id: "broker_agency_form").visible?).to be_truthy
end

When(/^.+ enters personal information$/) do
  @browser.text_field(class: /interaction-field-control-person-first-name/).set("Ricky")
  @browser.text_field(class: /interaction-field-control-person-last-name/).set("Martin")
  @browser.text_field(class: /interaction-field-control-person-dob/).set("10/10/1984")
  @browser.text_field(class: /interaction-field-control-person-email/).click
  @browser.text_field(class: /interaction-field-control-person-email/).set("ricky.martin@example.com")
  @browser.text_field(class: /interaction-field-control-person-npn/).set("109109109")
end

And(/^.+ enters broker agency information$/) do
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

And(/^(.+) enters? office locations information$/) do |named_person|
  enter_office_location(default_office_location)
end

And(/^.+ clicks? on Create Broker Agency$/) do
  @browser.element(class: /interaction-click-control-create-broker-agency/).wait_until_present
  scroll_then_click(@browser.button(class: /interaction-click-control-create-broker-agency/))
end


Then(/^.+ should see broker registration successful message$/) do
  @browser.element(text: /Your registration has been submitted. A response will be sent to the email address you provided once your application is reviewed./).wait_until_present
  expect(@browser.element(text: /Your registration has been submitted. A response will be sent to the email address you provided once your application is reviewed./).visible?).to be_truthy
end

And(/^.+ should see the list of broker applicants$/) do
end

Then(/^.+ clicks? on the current broker applicant show button$/) do
  @browser.element(class: /interaction-click-control-broker-show/).wait_until_present
  scroll_then_click(@browser.element(class: /interaction-click-control-broker-show/))
end

And(/^.+ should see the broker application$/) do
end

And(/^.+ clicks? on approve broker button$/) do
  @browser.element(class: /interaction-click-control-broker-approve/).wait_until_present
  scroll_then_click(@browser.element(class: /interaction-click-control-broker-approve/))
end

Then(/^.+ should see the broker successfully approved message$/) do
  @browser.element(text: /Broker applicant approved successfully./).wait_until_present
  expect(@browser.element(text: /Broker applicant approved successfully./).visible?).to be_truthy
end

And(/^.+ should receive an invitation email$/) do
  open_email("ricky.martin@example.com")
  expect(current_email.to).to eq(["ricky.martin@example.com"])
  current_email.should have_subject('DCHealthLink Invitation ')
end

When(/^.+ visits? invitation url in email$/) do
  invitation_link = links_in_email(current_email).first
  invitation_link.sub!(/https\:\/\/enroll1\.dchealthlink\.com/, 'http://localhost:3000')
  @browser.goto(invitation_link)
end

Then(/^.+ should see the login page$/) do
  @browser.element(class: /interaction-click-control-sign-in/).wait_until_present
end

When(/^.+ clicks? on Create Account$/) do
  @browser.a(text: /Create account/).wait_until_present
  @browser.a(text: /Create account/).click
end

When(/^.+ registers? with valid information$/) do
  @browser.text_field(name: "user[password_confirmation]").wait_until_present
  @browser.text_field(name: "user[email]").set("ricky.martin@example.com")
  @browser.text_field(name: "user[password]").set("12345678")
  @browser.text_field(name: "user[password_confirmation]").set("12345678")
  @browser.input(value: /Create account/).click
end

Then(/^.+ should see successful message with broker agency home page$/) do
  @browser.element(text: /Welcome! Your account has been created./).wait_until_present
  expect(@browser.element(text: /Welcome! Your account has been created./).visible?).to be_truthy

  @browser.h3(text: /Broker Agency \: Logistics Inc/).wait_until_present
  expect(@browser.h3(text: /Broker Agency \: Logistics Inc/).visible?).to be_truthy
end

Then(/^.+ should see no active broker$/) do
  @browser.element(text: /No Active Broker/).wait_until_present
  expect(@browser.element(text: /No Active Broker/).visible?).to be_truthy
end

When(/^.+ clicks? on Browse Brokers button$/) do
  @browser.a(text: /Browse Brokers/).wait_until_present
  @browser.a(text: /Browse Brokers/).click
end

Then(/^.+ should see broker agencies index view$/) do
  @browser.h4(text: /Broker Agencies/).wait_until_present
  expect(@browser.h4(text: /Broker Agencies/).visible?).to be_truthy
end

When(/^.+ searches broker agency by name$/) do
  search_div = @browser.div(class: "broker_agencies_search")
  search_div.wait_until_present

  search_div.text_field(name: "q").wait_until_present
  search_div.text_field(name: "q").set("Logistics")

  search_div.button(class: /btn/).wait_until_present
  search_div.button(class: /btn/).click
end

Then(/^.+ should see broker agency$/) do
  @browser.a(text: /Logistics Inc/).wait_until_present
  expect(@browser.a(text: /Logistics Inc/).visible?).to be_truthy
end

Then(/^.+ clicks? select broker button$/) do
  @browser.a(text: /Select Broker/).wait_until_present
  @browser.a(text: /Select Broker/).click
end

Then(/^.+ should see confirm modal dialog box$/) do
  @browser.element(class: /modal-dialog/).wait_until_present
  expect(@browser.div(class: /modal-body/).p(text: /Click Confirm to hire the selected broker\. Warning\: if you have an existing broker\,/).visible?).to be_truthy
  expect(@browser.div(class: /modal-body/).p(text: /they will be terminated effective immediately\./).visible?).to be_truthy
end

Then(/^.+ confirms? broker selection$/) do
  modal = @browser.div(class: 'modal-dialog')
  modal.input(value: /Confirm/).wait_until_present
  modal.input(value: /Confirm/).click
end

Then(/^.+ should see broker selected successful message$/) do
  @browser.element(text: /Successfully associated broker with your account./).wait_until_present
  expect(@browser.element(text: /Successfully associated broker with your account./).visible?).to be_truthy
end

And (/^.+ should see broker active for the employer$/) do
  expect(@browser.element(text: /Logistics Inc/).visible?).to be_truthy
  expect(@browser.element(text: /Ricky Martin/).visible?).to be_truthy
end

When(/^.+ terminates broker$/) do
  @browser.a(text: /Terminate/).wait_until_present
  @browser.a(text: /Terminate/).click

  @browser.text_field(class: "date-picker").wait_until_present
  @browser.text_field(class: "date-picker").set("07/23/2015")

  2.times { @browser.a(text: /Terminate/).click } # To collapse calender

  @browser.a(text: /Submit/).wait_until_present
  @browser.a(text: /Submit/).click
end

Then(/^.+ should see broker terminated message$/) do
  @browser.element(text: /Broker terminated successfully./).wait_until_present
  expect(@browser.element(text: /Broker terminated successfully./).visible?).to be_truthy
end

Then(/^.+ should see Employer and click on legal name$/) do
  @browser.a(text: /Legal LLC/).wait_until_present
  @browser.a(text: /Legal LLC/).click
end

Then(/^.+ should see the Employer Profile page as Broker$/) do
  wait_and_confirm_text(/Premium Billing Report/)
  expect(@browser.element(text: /I'm a Broker/).visible?).to be_truthy
end

Then(/^Primary Broker creates and publishes a plan year$/) do
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

Then(/^.+ sees employer census family created$/) do
  wait_and_confirm_text(/successfully created/)
end

Then(/^.+ should see the matched employee record form$/) do
  @browser.dd(text: /Legal LLC/).wait_until_present
  screenshot("broker_employer_search_results")
  expect(@browser.dd(text: /Legal LLC/).visible?).to be_truthy
end

Then(/^Broker Assisted is a family$/) do
  wait_and_confirm_text(/Broker Assisted/)
end

Then(/^.+ goes to the Consumer page$/) do
  wait_and_confirm_text(/My DC Health Link/)
end

# Then(/^.+ is on the consumer home page$/) do
#   binding.pry
#   @browser.a(class: 'interaction-click-control-shop-for-plans').wait_until_present
# end

Then(/^.+ shops for plans$/) do
  @browser.a(class: 'interaction-click-control-shop-for-plans').click 
end

Then(/^.+ sees covered family members$/) do
  wait_and_confirm_text(/Covered Family Members/)
  @browser.element(id: 'btn-continue').click
end

Then(/^.+ choses a healthcare plan$/) do
  wait_and_confirm_text(/Choose a healthcare plan/)
  wait_and_confirm_text(/Apply/)
  plan = @browser.a(class: 'interaction-click-control-select-plan')
  plan.click
end

Then(/^.+ continues to the consumer home page$/) do
  wait_and_confirm_text(/Continue/)
  @browser.a(text: /Continue/).click
end