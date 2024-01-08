# frozen_string_literal: true

Given(/^the user is on the "Waiting for your eligibility results..." page$/) do
  visit financial_assistance.wait_for_eligibility_response_application_path(application)
end

Then(/^the user should see the waiting for eligibility results page$/) do
  expect(page).to have_content(l10n("waiting_for_eligibility"))
end