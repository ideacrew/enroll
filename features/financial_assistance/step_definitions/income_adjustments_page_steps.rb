# frozen_string_literal: true

Then(/^they visit the income adjustments page via the left nav$/) do
  click_link 'Income Adjustments'
end

Given(/^the user answers no to having income adjustments$/) do
  visit current_path
  find(:css, '#has_deductions_false').click
end

And(/^the user answers clicks continue and remove$/) do
  find(:css, '.modal-continue-button').click
end

Then(/^the income adjustments choices should not show$/) do
  expect(page).to_not have_content 'Income adjustments you must report'
end

Given(/^the user answers yes to having income adjustments$/) do
  visit current_path
  find('#has_deductions_true').click
end

Then(/^the income adjustments choices should show$/) do
  expect(page).to have_content 'Income adjustments you must report'
  FinancialAssistance::Deduction::KINDS.each do |deduction_kind|
    expect(page).to have_content(FinancialAssistance::Deduction::DEDUCTION_TYPE[deduction_kind.to_sym])
  end
end

Given(/^the user checks a income adjustments checkbox$/) do
  find(:css, "#deduction_kind[value='alimony_paid']").set(true)
end

Then(/^the income adjustments form should show$/) do
  expect(page).to have_content 'Amount *'
  expect(page).to have_content 'How Often *'
end

Given(/^the user fills out the required income adjustments information$/) do
  fill_in 'deduction[amount]', with: '200'
  fill_in 'deduction[start_on]', with: '03/01/2018'
  find(:label, 'How Often *').click
  find('li', :text => 'Bi Weekly').click
end

Then(/^the user saves the income adjustments information$/) do
  click_button 'Save'
end

Then(/^the income adjustment should be saved on the page$/) do
  wait_for_ajax(3, 2)
  expect(page).to have_content '200.00'
  expect(page).to have_content '03/01/2018'
end

Then(/^the income adjustments checkbox should be unchecked$/) do
  expect(find(:css, "#deduction_kind[value='alimony_paid']")).not_to be_checked
end

Then(/^the income adjustment form should not show$/) do
  expect(page).to_not have_content 'AMOUNT *'
  expect(page).to_not have_content 'How Often *'
end

Given(/^divorce agreement year feature is disabled$/) do
  disable_feature :divorce_agreement_year, {registry_name: FinancialAssistanceRegistry}
end

Given(/^divorce agreement year feature is enabled$/) do
  enable_feature :divorce_agreement_year, {registry_name: FinancialAssistanceRegistry}
end

Then(/^the divorce agreement copy should show$/) do
  expect(page).to have_content 'from a divorce agreement finalized before January 1, 2019'
end

Then(/^the divorce agreement copy should not show$/) do
  expect(page).to_not have_content 'from a divorce agreement finalized before January 1, 2019'
end