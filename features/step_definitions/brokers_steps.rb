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
  #current_email.should have_subject('Invitation from your Employer to Sign up for Health Insurance at DC Health Link ')
end

When(/^.+ visits? invitation url in email$/) do
  invitation_link = links_in_email(current_email).first
  invitation_link.sub!(/https\:\/\/enroll1\.dchealthlink\.com/, 'http://localhost:3000')
  @browser.goto(invitation_link)
end

Then(/^.+ should see the login page$/) do
  @browser.element(class: /interaction-click-control-sign-in/).wait_until_present
end

Then(/^.+ should see the create account page$/) do
  @browser.element(class: /interaction-click-control-create-account/).wait_until_present
end

When(/^.+ clicks? on Create Account$/) do
  @browser.a(text: /Create account/).wait_until_present
  @browser.a(text: /Create account/).click
end

When(/^.+ registers? with valid information$/) do
  @browser.text_field(name: "user[password_confirmation]").wait_until_present
  @browser.text_field(name: "user[email]").set("ricky.martin@example.com")
  @browser.text_field(name: "user[password]").set("aA1!aA1!aA1!")
  @browser.text_field(name: "user[password_confirmation]").set("aA1!aA1!aA1!")
  @browser.input(value: /Create account/).click
end

Then(/^.+ should see successful message with broker agency home page$/) do
  @browser.element(text: /Welcome to DC Health Link. Your account has been created./).wait_until_present
  expect(@browser.element(text: /Welcome to DC Health Link. Your account has been created./).visible?).to be_truthy

  @browser.h3(text: /Broker Agency \: Logistics Inc/).wait_until_present
  expect(@browser.h3(text: /Broker Agency \: Logistics Inc/).visible?).to be_truthy
end

Then(/^.+ should see no active broker$/) do
  @browser.element(class: /interaction-click-control-browse-brokers/).wait_until_present
  expect(@browser.element(text: /You have no active Broker/).visible?).to be_truthy
end

When(/^.+ clicks? on Browse Brokers button$/) do
  click_when_present(@browser.element(class: /interaction-click-control-browse-brokers/))
end

Then(/^.+ should see broker agencies index view$/) do
  @browser.h1(text: /Broker Agencies/).wait_until_present
  expect(@browser.h1(text: /Broker Agencies/).visible?).to be_truthy
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
  logistics = @browser.as(text: /Select Broker/).last
  logistics.click
end

Then(/^.+ should see confirm modal dialog box$/) do
  wait_and_confirm_text /Broker Selection Confirmation/
end

Then(/^.+ confirms? broker selection$/) do
  modal = @browser.divs(class: 'modal-dialog').last
  modal.input(value: /Confirm/).wait_until_present
  modal.input(value: /Confirm/).click
end

Then(/^.+ should see broker selected successful message$/) do
  @browser.element(text: /Your broker has been notified of your selection and should contact you shortly. You can always call or email him or her directly. If this is not the broker you want to use, select 'Change Broker'./).wait_until_present
  expect(@browser.element(text: /Your broker has been notified of your selection and should contact you shortly. You can always call or email him or her directly. If this is not the broker you want to use, select 'Change Broker'./).visible?).to be_truthy
end

And (/^.+ should see broker active for the employer$/) do
  @browser.element(text: /Logistics Inc/i).wait_until_present
  expect(@browser.element(text: /Logistics Inc/).visible?).to be_truthy
  expect(@browser.element(text: /Ricky Martin/i).visible?).to be_truthy
end

When(/^.+ terminates broker$/) do
  @browser.a(text: /Change Broker/i).wait_until_present
  @browser.a(text: /Change Broker/i).click
  @browser.element(text: /Broker Termination Confirmation/).wait_until_present
  @browser.a(text: /Terminate Broker/i).wait_until_present
  @browser.a(text: /Terminate Broker/i).click

  #according to 2096 remove terminate in future
  #@browser.text_field(class: "date-picker").wait_until_present
  #@browser.text_field(class: "date-picker").set("07/23/2015")

  #2.times { @browser.a(text: /Terminate/).click } # To collapse calender

  #@browser.a(text: /Submit/).wait_until_present
  #@browser.a(text: /Submit/).click
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
  @browser.element(text: /I'm a Broker/).wait_until_present
  expect(@browser.element(text: /I'm a Broker/).visible?).to be_truthy
end

Then(/^.* creates and publishes a plan year$/) do
  click_when_present(@browser.element(class: /interaction-click-control-benefits/))
  click_when_present(@browser.element(class: /interaction-click-control-add-plan-year/))
  start_on = @browser.p(text: /SELECT START ON/i)
  click_when_present(start_on)
  start_on = @browser.li(text: /SELECT START ON/i)
  click_when_present(start_on.parent().lis()[1])
  #id="plan_year_benefit_groups_attributes_0_relationship_benefits_attributes_0_premium_pct"
  #@browser.text_field(id: id).set(50)
  @browser.text_field(name: "plan_year[fte_count]").fire_event('onclick')
  @browser.text_field(name: "plan_year[fte_count]").set("3")
  @browser.a(class: /interaction-click-control-continue/).wait_until_present
  @browser.a(class: /interaction-click-control-continue/).fire_event('onclick')
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

  @browser.button(class: /interaction-click-control-create-plan-year/).fire_event("onclick")
  @browser.element(class: /alert-notice/, text: /Plan Year successfully created./).wait_until_present
  click_when_present(@browser.element(class: /interaction-click-control-benefits/))
  click_when_present(@browser.element(class: /interaction-click-control-publish-plan-year/))
  # @browser.refresh
end

Then(/^.+ sees employer census family created$/) do
  wait_and_confirm_text(/successfully created/)
end

Then(/^.+ should see the matched employee record form$/) do
  @browser.p(text: /Legal LLC/).wait_until_present
  screenshot("broker_employer_search_results")
  expect(@browser.p(text: /Legal LLC/).visible?).to be_truthy
end

Then(/^Broker Assisted is a family$/) do
  wait_and_confirm_text(/Broker Assisted/)
end

Then(/^.+ goes to the Consumer page$/) do
  broker_assist_row = @browser.td(text: /Broker Assisted/).parent
  broker_assist_row.a(text: /Consumer/).click
  wait_and_confirm_text(/My DC Health Link/)
end

# Then(/^.+ is on the consumer home page$/) do
#   @browser.a(class: 'interaction-click-control-shop-for-plans').wait_until_present
# end

Then(/^.+ shops for plans$/) do
  @browser.a(class: 'interaction-click-control-shop-for-plans').click
end

Then(/^.+ sees covered family members$/) do
  wait_and_confirm_text(/Choose Benefits: Covered Family Members/)
  @browser.element(id: 'btn-continue').click
end

Then(/^.+ choses a healthcare plan$/) do
  wait_and_confirm_text(/Choose Plan/i)
  wait_and_confirm_text(/Apply/)
  plan = @browser.a(class: 'interaction-click-control-select-plan')
  plan.click
end

Then(/^.+ continues to the consumer home page$/) do
  wait_and_confirm_text(/Continue/)
  @browser.a(text: /Continue/).click
end
