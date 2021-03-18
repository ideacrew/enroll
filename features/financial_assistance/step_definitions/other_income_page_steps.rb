# frozen_string_literal: true

Given(/^the unemployment income feature is enabled$/) do
  skip_this_scenario unless FinancialAssistanceRegistry[:unemployment_income].enabled?
end

Then(/^they visit the other income page via the left nav$/) do
  click_link 'Other Income'
end

Then(/^the user will navigate to the Other Income page for the corresponding applicant$/) do
  expect(page).to have_content "Other Income for"
end

Given(/^the user answers no to having other income$/) do
  find("#has_other_income_false").click
end

Then(/^the other income choices should not show$/) do
  expect(page).to_not have_content "Common types of income you must report."
end

Given(/^the user answers yes to having other income$/) do
  find("#has_other_income_true").click
end

Then(/^the other income choices should show$/) do
  expect(page).to have_content "Common types of income you must report"
end

Given(/^the user answers no to having unemployment income$/) do
  find("#has_unemployment_income_false").click
end

Then(/^the unemployment income choices should not show$/) do
  expect(page).to_not have_content "Add Another Unemployment Income"
end

Given(/^the user answers yes to having unemployment income$/) do
  find("#has_unemployment_income_true").click
end

Then(/^the unemployment income choices should show$/) do
  expect(page).to have_content "Add Another Unemployment Income"
end

Given(/^the user checks a other income checkbox$/) do
  find(:css, "#other_income_kind[value='alimony_and_maintenance']").set(true)
end

Then(/^the other income form should show$/) do
  expect(page).to have_content "Amount *"
  expect(page).to have_content "HOW OFTEN *"
end

Then(/^the unemployment income form should show$/) do
  expect(page).to have_content "Amount *"
  expect(page).to have_content "HOW OFTEN *"
end

Given(/^the user fills out the required other income information$/) do
  fill_in 'income[amount]', with: '100'
  fill_in 'income[start_on]', with: '1/01/2018'
  find_all(".interaction-choice-control-income-frequency-kind")[0].click
  find_all('.interaction-choice-control-income-frequency-kind-1')[0].click
end

Then(/^the save button should be enabled$/) do
  expect(find(:css, '.interaction-click-control-save')[:class].include?('disabled')).to eq(false)
end

Then(/^the user saves the other income information$/) do
  click_button 'Save'
end

Then(/^the other income information should be saved on the page$/) do
  expect(page).to have_content '100.00'
  expect(page).to have_content '1/01/2018'
end

When(/^the user cancels the form$/) do
  find(".interaction-click-control-cancel").click
end

Then(/^the other income checkbox should be unchecked$/) do
  expect(find(:css, "#other_income_kind[value='alimony_and_maintenance']")).not_to be_checked

end

Then(/^the other income form should not show$/) do
  expect(page).to_not have_content "AMOUNT *"
  expect(page).to_not have_content "HOW OFTEN *"
end

When(/^the user clicks the BACK TO ALL HOUSEHOLD MEMBERS link$/) do
  click_link('BACK TO ALL HOUSEHOLD MEMBERS')
end

Then(/^a modal should show asking the user are you sure you want to leave this page$/) do
  expect(page).to have_content "Are you sure you want to leave this page?"
end
