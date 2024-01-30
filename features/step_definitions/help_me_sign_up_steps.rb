# frozen_string_literal: true

Given(/^an IVL Broker Agency exists$/) do
  broker_name = "IVL Broker Agency"
  broker_agency_organization broker_name, legal_name: broker_name, dba: broker_name

  broker_agency_profile(broker_name).update_attributes!(aasm_state: 'is_approved', market_kind: 'individual', accept_new_clients: true)
end

And(/Individual has broker assigned to them/) do
  family = Family.first
  broker_id = Person.where(:broker_role.exists => true).last.id
  profile_id = BenefitSponsors::Organizations::GeneralOrganization.first.profiles.first.id
  family.broker_agency_accounts << BenefitSponsors::Accounts::BrokerAgencyAccount.new(benefit_sponsors_broker_agency_profile_id: profile_id, writing_agent_id: broker_id, is_active: true, start_on: Date.today)
  family.save!
end

And(/^Individual clicks on the Help Me Sign Up link?/) do
  find("#help_with_plan_shopping_btn").click
end

And(/^Individual clicks on the Get Help Signing Up button?/) do
  find(".interaction-click-control-get-help-signing-up").click
end

And(/^Individual clicks on the Help from an Expert link?/) do
  path = benefit_sponsors.staff_index_profiles_broker_agencies_broker_agency_profiles_path
  find("a[href='#{path}']").click
end

And(/^Individual selects a broker?/) do

  # Wait for the div to appear for a maximum of 10 seconds
  wait_time = 20
  start_time = Time.now

  # Loop until the div is found or the timeout is reached
  while (Time.now - start_time) < wait_time
    if page.has_css?(".broker_select_button")
      break
    end
    sleep 0.5 # Wait for a short interval before checking again
  end

  # Perform actions after the div appears
  if page.has_css?(".broker_select_button")
    expect(page).to have_css(".broker_select_button")
    find(".broker_select_button").click
  else
    expect(page).to have_css(".broker_select_button")
    find(".broker_select_button").click
  end
end

And(/^Individual clicks on Select this Broker button$/) do
  find(".help_button").click
end

And(/^Individual clicks on close button$/) do
  find(".interaction-click-control-×").click
end

And(/^the page is refreshed$/) do
  visit current_path
end

And(/^Individual clicks on the My Broker link$/) do
  path = brokers_insured_families_path(tab: 'broker')
  find("a[href='#{path}']").click
end
