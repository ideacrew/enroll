# frozen_string_literal: true

Given(/^that a family has a Financial Assistance application in the (.*?) state$/) do |state|
  # draft, submitted, determination_response_error, determined
  FactoryBot.create(:hbx_profile)
  application.update_attributes(aasm_state: state)
end

And(/^the primary applicant age greater than (.*?)$/) do |age|
  @application.primary_applicant.update_attributes(dob: (age.to_i + 1).years.ago)
end

And(/^the user navigates to the “Help Paying For Coverage” portal$/) do
  visit financial_assistance.applications_path
end

When(/^the user clicks the “Action” dropdown corresponding to the (.*?) application$/) do |_status|
  # draft, submitted, determination_response_error, determined
  find(".dropdown-toggle", :text => "Actions").click
end

Then(/^the "Review Application" link will be disabled$/) do
  expect(find_link("Review Application")[:disabled] == 'true')
end

Then(/^the “Review Application” link will be actionable$/) do
  expect(find_link("Review Application")[:disabled] == 'false')
end

And(/^clicks the “Review Application” link$/) do
  click_link 'Review Application'
end

Then(/^the user will navigate to the Review Application page$/) do
  if EnrollRegistry.feature_enabled?(:financial_assistance) &&
     FinancialAssistanceRegistry.feature_enabled?(:display_medicaid_question)
    expect(page).to have_content(l10n("faa.medicaid_question"))
  end
  expect(page).to have_content("Review Your Application")
end

And(/^the user fills out the review and submit details$/) do
  sleep 1
  find(".btn", text: "CONTINUE").click
  sleep 1
  choose("mailed_no")
  continue_button = page.all('input').detect { |input| input[:type] == 'submit' }
  continue_button.click
  # Submit Application
  find("#application_medicaid_terms").click
end
