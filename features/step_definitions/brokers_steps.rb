When(/^I visit the HBX Broker Agency portal$/) do
  @browser.goto("http://localhost:3000/")
  # screenshot("enroll_home_page")
  @browser.a(class: /interaction-click-control-broker-registration/).wait_until_present
  @browser.a(class: /interaction-click-control-broker-registration/).click
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
  @browser.text_field(class: /interaction-field-control-office-location-address-address-1/).set("623a Spalding Ct")
  @browser.text_field(class: /interaction-field-control-office-location-address-address-2/).set("Suite 200")
  @browser.text_field(class: /interaction-field-control-office-location-address-city/).set("McLean")
  @browser.text_field(class: /interaction-field-control-office-location-address-state/).set("VA")
  @browser.text_field(class: /interaction-field-control-office-location-address-zip/).set("22108")
  @browser.text_field(class: /interaction-field-control-office-location-phone-area-code/).set("202")
  @browser.text_field(class: /interaction-field-control-office-location-phone-number/).set("1110000")
  @browser.text_field(class: /interaction-field-control-office-location-phone-extension/).set("1111")
end

When(/^I click on create broker agency button$/) do
  @browser.element(class: /interaction-click-control-create-broker-agency/).wait_until_present
  @browser.element(class: /interaction-click-control-create-broker-agency/).click
end

Then(/^I should see a successful broker create message$/) do
  binding.pry
  @browser.element(text: /Successfully created Broker Agency Profile/).wait_until_present
  # screenshot("show_broker_ageny_profile_page")
  expect(@browser.element(text: /Successfully created Broker Agency Profile/).visible?).to be_truthy
end