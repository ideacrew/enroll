When(/^I visit the HBX Broker Agency portal$/) do
  @browser.goto("http://localhost:3000/")
  # screenshot("enroll_home_page")
  @browser.element(class: /interaction-click-control-broker-registration/).wait_until_present
  @browser.element(class: /interaction-click-control-broker-registration/).click
  # screenshot("broker_agency_portal_click")
  @browser.radio(class: /interaction-choice-control-value-new-broker-agency/).wait_until_present
  @browser.radio(class: /interaction-choice-control-value-new-broker-agency/).fire_event("onclick")
end

And(/^I should see an initial form to enter personal information$/) do
  @browser.element(class: /interaction-click-control-create-broker-agency/).wait_until_present
  @browser.text_field(class: /interaction-field-control-person-first-name/).wait_until_present
  @browser.text_field(class: /interaction-field-control-person-first-name/).set("Ricky")
  @browser.text_field(class: /interaction-field-control-person-last-name/).set("Martin")
  @browser.text_field(class: /interaction-field-control-person-dob/).set("10/10/1984")
  @browser.text_field(class: /interaction-field-control-person-email/).click
  @browser.text_field(class: /interaction-field-control-person-email/).set("ricky.martin@example.com")
  @browser.text_field(class: /interaction-field-control-person-npn/).set("109109109")
end


And(/^I should see a second fieldset to enter broker agency information$/) do
  @browser.text_field(class: /interaction-field-control-organization-legal-name/).set("Prometric Inc")
  @browser.text_field(class: /interaction-field-control-organization-dba/).set("Prometric Inc")
  @browser.text_field(class: /interaction-field-control-organization-fein/).set("890890891")
  entity_kind = @browser.div(class: /interaction-choice-control-organization-entity-kind/)
  entity_kind.click
  entity_kind.li(text: /S Corporation/).click
  #Address
  @browser.text_field(class: /interaction-field-control-broker-corporate-npn/).set("890890892")
  @browser.text_field(class: /interaction-field-control-broker-home-page/).set("www.prometric.example.com")

  practice_area = @browser.div(class: /selectric-interaction-choice-control-broker-agency-practice-area/)
  practice_area.click
  practice_area.li(text: /Shop/).click
  @browser.text_field(class: /interaction-field-control-broker-agency-languages-spoken/).set("English")
  # @browser.checkbox(class: /interaction-choice-control-broker-agency-evening-weekend-hours/).set
  @browser.checkboxes.first.set # evening/weekend hours
  @browser.checkboxes.last.set # accept new clients
end

And(/^I should see a third fieldset to enter more office location information$/) do
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

When(/^I click on create broker agency button$/) do
  @browser.element(class: /interaction-click-control-create-broker-agency/).wait_until_present
  @browser.element(class: /interaction-click-control-create-broker-agency/).click
end

Then(/^I should see a successful broker registration message$/) do
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
Then(/^I click on show button for the broker$/) do
  @browser.element(class: /interaction-click-control-broker-show/).wait_until_present
  scroll_then_click(@browser.element(class: /interaction-click-control-broker-show/))
end

And(/^I click on approve broker$/) do
  @browser.element(class: /interaction-click-control-broker-approve/).wait_until_present
  scroll_then_click(@browser.element(class: /interaction-click-control-broker-approve/))
end

Then(/^I should see a broker successful approve message$/) do
  @browser.element(text: /Broker applicant approved successfully./).wait_until_present
  expect(@browser.element(text: /Broker applicant approved successfully./).visible?).to be_truthy
end