# frozen_string_literal: true

Then(/^the user is on the Your Preferences page$/) do
  find('#eligibility_easier_yes').click
  find('#mailed_yes').click if FinancialAssistanceRegistry.feature_enabled?(:voter_registration_through_hbx)
  expect(page).to have_content('Your Preferences')
end

Given(/^the user has a parent living outside the home$/) do
  FinancialAssistance::Application.first.update_attributes!(attestation_terms: true, parent_living_out_of_home_terms: true)
end

Then(/^the answer to "([^"]*)" is defaulted to "([^"]*)"$/) do |_arg1, _arg2|
  find('#eligibility_easier_yes').should be_checked
end

Then(/^the field corresponding to renewal should be defaulted to (\d+) years in the data model$/) do |_year|
  application.years_to_renew.to_s == '3'
end

When(/^the user selects (\d+) years for eligibility length question$/) do |_arg1|
  find('input[value="3"]').click
end

Then(/^the "([^"]*)" question displays$/) do |question|
  expect(page).to have_content(question)
end

Given(/^the user selects I DISAGREE$/) do
  choose('eligibility_easier_no')
end
