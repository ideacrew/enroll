require File.join(File.dirname(__FILE__), "integration_steps.rb")
require File.join(File.dirname(__FILE__), "employers_steps.rb")

When(/^I visit the Broker Agency portal$/) do
  @browser.goto("http://localhost:3000/")
  @browser.a(text: /Broker Agency Portal/).wait_until_present
  @browser.a(text: /Broker Agency Portal/).click
  screenshot("broker_agency_start")
  @browser.a(text: /Create account/).wait_until_present
  @browser.a(text: /Create account/).click
end

And(/^I should see an initial form to enter information about my Broker Agency and myself$/) do
  @browser.text_field(name: "organization[first_name]").wait_until_present
end

When(/^I complete the Broker Agency form$/) do
  @browser.text_field(name: "organization[first_name]").set("Doe")
  @browser.text_field(name: "organization[last_name]").set("John")
  @browser.text_field(name: "jq_datepicker_ignore_organization[dob]").set("11/10/1982")
  @browser.text_field(name: "organization[first_name]").click

  @browser.text_field(name: "organization[legal_name]").set("Turner Broker Agency, Inc")
  @browser.text_field(name: "organization[fein]").set("127776999")
  input_field = @browser.divs(class: "selectric-interaction-choice-control-organization-entity-kind").first
  input_field.click
  input_field.li(text: /C Corporation/).click
  @browser.text_field(name: "organization[office_locations_attributes][0][address_attributes][address_1]").set("100 North Street")
  @browser.text_field(name: "organization[office_locations_attributes][0][address_attributes][address_2]").set("Suite 990")
  @browser.text_field(name: "organization[office_locations_attributes][0][address_attributes][city]").set("Sterling")
  @browser.text_field(name: "organization[office_locations_attributes][0][address_attributes][state]").set("VA")
  @browser.text_field(name: "organization[office_locations_attributes][0][address_attributes][zip]").set("20166")
  @browser.text_field(name: "organization[office_locations_attributes][0][phone_attributes][area_code]").set("678")
  @browser.text_field(name: "organization[office_locations_attributes][0][phone_attributes][number]").set("1230987")
  @browser.p(:text => /Select Practice Area/).click
  @browser.li(:text => /both/i).wait_until_present(2)
  @browser.li(:text => /both/i).click
  screenshot("broker_agency_signup")
  @browser.button(class: "interaction-click-control-create-broker-agency").click
end

Then(/^I should see the Broker Agency Landing Page$/) do
  @browser.h3(text: /Broker Agency : Turner Broker Agency, Inc/).wait_until_present(10)
  screenshot("broker_agency_profile_page")
end
