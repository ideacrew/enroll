When(/^I visit the HBX Broker Agency portal$/) do
  @browser.goto("http://localhost:3000/")
  screenshot("enroll_home_page")
  @browser.a(class: /interaction-click-control-broker-agency-portal/).wait_until_present
  @browser.a(class: /interaction-click-control-broker-agency-portal/).click
  screenshot("broker_agency_portal_click")
  @browser.a(class: /interaction-click-control-create-account/).wait_until_present
  screenshot("broker_agency_sign_in_page")
  @browser.a(class: /interaction-click-control-create-account/).click
  screenshot("broker_agency_create_account_click")
end

And(/^I should see an initial form to enter broker agency information$/) do
  # Broker agency info
  @browser.text_field(class: /interaction-field-control-organization-broker-agency-profile-attributes-legal-name/).set("Global LLC")
  @browser.text_field(class: /interaction-field-control-organization-broker-agency-profile-attributes-dba/).set("Systems")
  @browser.text_field(class: /interaction-field-control-organization-broker-agency-profile-attributes-fein/).set("897897897")
  @browser.div(class: /interaction-choice-control-organization-broker-agency-profile-attributes-entity-kind/).wait_until_present
  entity_kind = @browser.div(class: /interaction-choice-control-organization-broker-agency-profile-attributes-entity-kind/)
  entity_kind.click
  entity_kind.li(text: /Partnership/).click
  #Address
  @browser.text_field(class: /interaction-field-control-organization-broker-agency-profile-attributes-home-page/).set("www.example.com")
  @browser.text_field(class: /interaction-field-control-organization-office-locations-attributes-0-address-attributes-address-1/).set("910 I St N West")
  @browser.text_field(class: /interaction-field-control-organization-office-locations-attributes-0-address-attributes-address-2/).set("Suite 200")
  @browser.text_field(class: /interaction-field-control-organization-office-locations-attributes-0-address-attributes-city/).set("Atlanta")
  @browser.text_field(class: /interaction-field-control-organization-office-locations-attributes-0-address-attributes-state/).set("GA")
  @browser.text_field(class: /interaction-field-control-organization-office-locations-attributes-0-address-attributes-zip/).set("30338")
  #Phone
  @browser.text_field(class: /interaction-field-control-organization-office-locations-attributes-0-phone-attributes-area-code/).set("980")
  @browser.text_field(class: /interaction-field-control-organization-office-locations-attributes-0-phone-attributes-number/).set("9809800")
  @browser.text_field(class: /interaction-field-control-organization-office-locations-attributes-0-phone-attributes-extension/).set("1000")
  @browser.text_field(class: /interaction-field-control-organization-office-locations-attributes-0-phone-attributes-extension/).set("1000")
end

And(/^I should see a second fieldset to enter more broker agency information$/) do
  # More broker agency info
  practice_area = @browser.divs(class: /selectric-wrapper/, text: /Select Practice Area/).last
  practice_area.click
  practice_area.li(index: 1).click
  @browser.text_field(class: /interaction-field-control-organization-broker-agency-profile-attributes-languages-spoken/).set("English")
  @browser.checkbox(class: /interaction-choice-control-value-organization-broker-agency-profile-attributes-working-hours/).set
  @browser.checkbox(class: /interaction-choice-control-value-organization-broker-agency-profile-attributes-accept-new-clients/).set
end

And(/^I should see a third fieldset to enter primary broker information$/) do
  @browser.text_field(class: /interaction-field-control-organization-broker-agency-profile-attributes-broker-agency-contacts-attributes-0-first-name/).set("John")
  @browser.text_field(class: /interaction-field-control-organization-broker-agency-profile-attributes-broker-agency-contacts-attributes-0-last-name/).set("Cena")

  provider_kind = @browser.divs(class: /selectric-wrapper/, text: /Select Provider Kind/).last
  provider_kind.click
  provider_kind.li(index: 1).click

  @browser.text_field(class: /interaction-field-control-organization-broker-agency-profile-attributes-broker-agency-contacts-attributes-0-broker-role-attributes-npn/).set("786123098")
  @browser.text_field(class: /interaction-field-control-organization-broker-agency-profile-attributes-broker-agency-contacts-attributes-0-emails-attributes-0-address/).set("john.cena@example.com")
end

And(/^I should see a radio button asking if i'm the primary broker$/) do
  @browser.radio(class: /interaction-choice-control-value-is-primary-broker-0/).wait_until_present
  @browser.radio(class: /interaction-choice-control-value-is-primary-broker-0/).fire_event("onclick") # primary broker no
end

And(/^I should see a fourth fieldset to enter my name, email and phone that is only required to complete if i'm not the primary broker$/) do
  @browser.text_field(class: /interaction-field-control-first-name/).wait_until_present
  expect(@browser.text_field(class: /interaction-field-control-first-name/).visible?).to be_truthy
  expect(@browser.text_field(class: /interaction-field-control-last-name/).visible?).to be_truthy
  expect(@browser.text_field(class: /interaction-field-control-last-name/).visible?).to be_truthy
end

And(/^My user data from existing the fieldset values are prefilled using data from my existing Person record$/) do
  @browser.text_field(class: /interaction-field-control-first-name/).set("Trey")
  @browser.text_field(class: /interaction-field-control-last-name/).set("Evans")
end

When(/^I click on create broker agency button$/) do
  @browser.element(class: /interaction-click-control-create-broker-agency/).wait_until_present
  screenshot("broker_agency_new_page_with_info")
  @browser.element(class: /interaction-click-control-create-broker-agency/).click
end

Then(/^I should see a successful broker create message$/) do
  @browser.element(text: /Successfully created Broker Agency Profile/).wait_until_present
  screenshot("show_broker_ageny_profile_page")
  expect(@browser.element(text: /Successfully created Broker Agency Profile/).visible?).to be_truthy
end