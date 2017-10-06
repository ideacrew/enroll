Given(/^that a family has a Financial Assistance application in the “draft” state$/) do
  login_as consumer, scope: :user
  visit financial_assistance_applications_path
  create_plan
  application
end

Given(/^the user navigates to the “Help Paying For Coverage” portal$/) do
  visit financial_assistance_applications_path
end

When(/^the user clicks the “Action” dropdown corresponding to the “draft” application$/) do
  find_button('Actions').visible?
  click_button('Actions')
end

Then(/^the “View Eligibility Determination” link will be disabled$/) do
  find_link('View Eligibility Determination')['disabled'].should == 'disabled'
end

Given(/^that a family has a Financial Assistance application in the “submitted” state$/) do
  login_as consumer, scope: :user
  visit financial_assistance_applications_path
  create_plan
  application
  application.update_attributes(:aasm_state => 'submitted')
end

When(/^clicks the “Action” dropdown corresponding to the “submitted” application$/) do
  find_button('Actions').visible?
  click_button('Actions')
end

Given(/^that a family has a Financial Assistance application in the “determination_response_error” state$/) do
  login_as consumer, scope: :user
  visit financial_assistance_applications_path
  create_plan
  application
  application.update_attributes(:aasm_state => 'determination_response_error')
end

When(/^the user clicks the “Action” dropdown corresponding to the “determination_response_error” application$/) do
  find_button('Actions').visible?
  click_button('Actions')
  screenshot_and_post_to_slack('application_index_page_screenshot', channel: 'new_faa_team')
end

Given(/^that a family has a Financial Assistance application in the “determined” state$/) do
  login_as consumer, scope: :user
  visit financial_assistance_applications_path
  create_plan
  application
  application.update_attributes(:aasm_state => 'determined')
end

When(/^clicks the “Action” dropdown corresponding to the “determined” application$/) do
  find_button('Actions').visible?
  click_button('Actions')
end

Then(/^the “View Eligibility Determination” link will be actionable$/) do
  find_link('View Eligibility Determination').visible?
  click_link('View Eligibility Determination')
end

Given(/^clicks the “View Eligibility Determination” link$/) do
  find_link('View Eligibility Determination').visible?
  click_link('View Eligibility Determination')
end

Then(/^the user will navigate to the Eligibility Determination page for that specific application$/) do
  expect(page).to have_content('Eligibility Results')
end
