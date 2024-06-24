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
  if EnrollRegistry[:bs4_consumer_flow].enabled?

  else
  find('.interaction-click-control-help-me-sign-up').click
  end
end

And(/^Individual clicks on the Get Help Signing Up button?/) do
  find(".interaction-click-control-get-help-signing-up").click
end

And(/^Individual clicks on the Help from an Expert link?/) do
  path = benefit_sponsors.staff_index_profiles_broker_agencies_broker_agency_profiles_path
  find("a[href='#{path}']").click
end

And(/^Individual selects a broker?/) do
  find(".broker_select_button", wait: 5).click
end

And(/^Individual confirms a broker/) do
  find(IvlHomepage.select_this_broker).click
end

And(/^Individual sees your expert widget/) do
  expect(page).to have_content(l10n("insured.your_broker_or_assister"))
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
