# frozen_string_literal: true

Given(/^that a user with a family has a Financial Assistance application in the "draft" state$/) do
  login_as consumer, scope: :user
  step "the consumer is RIDP verified"
  visit financial_assistance.applications_path
  create_plan
  application aasm_state: 'draft'
end

Given(/^the user navigates to the "Help Paying For Coverage" portal$/) do
  visit financial_assistance.applications_path
end

When(/^the user clicks the "Action" dropdown corresponding to the "draft" application$/) do
  find_button('Actions').visible?
  click_button('Actions')
end

Then(/^the "View Eligibility Determination" link will be disabled$/) do
  find_link('View Eligibility Determination')['disabled'].should == 'disabled'
end

Given(/^that a user with a family has a Financial Assistance application in the "submitted" state$/) do
  login_as consumer, scope: :user
  step "the consumer is RIDP verified"
  visit financial_assistance.applications_path
  create_plan
  application
  application.update_attributes(:aasm_state => 'submitted')
end

When(/^clicks the "Action" dropdown corresponding to the "submitted" application$/) do
  find_button('Actions').visible?
  click_button('Actions')
end

Given(/^that a user with a family has a Financial Assistance application in the "determination_response_error" state$/) do
  login_as consumer, scope: :user
  step "the consumer is RIDP verified"
  visit financial_assistance.applications_path
  create_plan
  application
  application.update_attributes(:aasm_state => 'determination_response_error')
end

When(/^the user clicks the "Action" dropdown corresponding to the "determination_response_error" application$/) do
  find_button('Actions').visible?
  click_button('Actions')
end

Given(/^that a user with a family has a Financial Assistance application in the "cancelled" state$/) do
  login_as consumer, scope: :user
  step "the consumer is RIDP verified"
  visit financial_assistance.applications_path
  create_plan
  application
  application.update_attributes(:aasm_state => 'cancelled')
end

When(/^the user clicks the "Action" dropdown corresponding to the "cancelled" application$/) do
  find_button('Actions').visible?
  click_button('Actions')
end

Given(/^that a user with a family has a Financial Assistance application in the "terminated" state$/) do
  login_as consumer, scope: :user
  step "the consumer is RIDP verified"
  visit financial_assistance.applications_path
  create_plan
  application
  application.update_attributes(:aasm_state => 'terminated')
end

When(/^clicks the "Action" dropdown corresponding to the "terminated" application$/) do
  find_button('Actions').visible?
  click_button('Actions')
end

Given(/^that a user with a family has a Financial Assistance application in the "determined" state$/) do
  login_as consumer, scope: :user
  step "the consumer is RIDP verified"
  visit financial_assistance.applications_path
  create_plan
  application
  application.update_attributes(:aasm_state => 'determined')
end

When(/^clicks the "Action" dropdown corresponding to the "determined" application$/) do
  find_button('Actions').visible?
  click_button('Actions')
end

Then(/^the "View Eligibility Determination" link will be actionable$/) do
  find_link('View Eligibility Determination').visible?
  click_link('View Eligibility Determination')
end

Given(/^clicks the "View Eligibility Determination" link$/) do
  find_link('View Eligibility Determination').visible?
  click_link('View Eligibility Determination')
end

Then(/^the user will navigate to the Eligibility Determination page for that specific application$/) do
  expect(page).to have_content('Eligibility Results')
end

Given(/^that a user with a family has a Financial Assistance application with tax households$/) do
  login_as consumer, scope: :user
  step "the consumer is RIDP verified"
  visit financial_assistance.applications_path
  create_plan
  allow(application).to receive(:is_application_valid?).and_return(true)
end

Given(/^the user has 0% CSR$/) do
  create_dummy_ineligibility(application)
end

Given(/^the user has a 73% CSR$/) do
  create_dummy_eligibility(application)
end

Then(/^the user will navigate to the Eligibility Determination page and will not find CSR text present$/) do
  expect(page).to have_content('Eligibility Results')
  expect(page).not_to have_content('These people are eligible for monthly premium reductions of')
  expect(page).not_to have_content('They also qualify for extra savings called')
end

Then(/^the user will navigate to the Eligibility Determination page and will find CSR text present$/) do
  expect(page).to have_content('Eligibility Results')
  expect(page).to have_content('These people qualify for')
end

And(/^the application has applicant with max_aptc and csr$/) do
  setup_applicant_eligible_for_max_aptc_and_csr(application)
end

Then(/^the user will navigate to the Eligibility Results page and will find APTC and CSR eligibility text$/) do
  expect(page.has_css?(IvlIapEligibilityResults.eligibility_results)).to eq true
  expect(page.has_css?(IvlIapEligibilityResults.tax_household)).to eq true
  expect(page.has_css?(IvlIapEligibilityResults.aptc_heading)).to eq true
  expect(page.has_css?(IvlIapEligibilityResults.aptc_text)).to eq true
  expect(page.has_css?(IvlIapEligibilityResults.full_name)).to eq true
  expect(page.has_css?(IvlIapEligibilityResults.csr)).to eq true
  expect(page.has_css?(IvlIapEligibilityResults.csr_73_87_or_94_text)).to eq true
  expect(page.has_css?(IvlIapEligibilityResults.next_steps)).to eq true
  expect(page.has_css?(IvlIapEligibilityResults.next_steps_text)).to eq true
  expect(page.has_css?(IvlIapEligibilityResults.continue_text)).to eq false
  expect(page.has_css?(IvlIapEligibilityResults.return_to_account_home)).to eq true
  expect(page.has_css?(IvlIapEligibilityResults.your_application_reference_2)).to eq true
end

And(/^the application has applicant with medicaid_or_chip$/) do
  setup_applicant_eligible_for_medicaid_or_chip(application)
end

Then(/^the user will navigate to the Eligibility Results page and will find Medicaid or CHIP eligibility text$/) do
  expect(page.has_css?(IvlIapEligibilityResults.eligibility_results)).to eq true
  expect(page.has_css?(IvlIapEligibilityResults.tax_household)).to eq true
  expect(page.has_css?(IvlIapEligibilityResults.medicaid_or_chip_heading)).to eq true
  expect(page.has_css?(IvlIapEligibilityResults.medicaid_or_chip_text)).to eq true
  expect(page.has_css?(IvlIapEligibilityResults.next_steps)).to eq true
  expect(page.has_css?(IvlIapEligibilityResults.all_medicaid_next_steps_continue_text)).to eq true
  expect(page.has_css?(IvlIapEligibilityResults.return_to_account_home)).to eq true
  expect(page.has_css?(IvlIapEligibilityResults.your_application_reference_2)).to eq true
end

And(/^the application has applicant with uqhp and non_magi_reasons$/) do
  setup_applicant_eligible_for_uqhp_and_non_magi_reasons(application)
end

Then(/^the user will navigate to the Eligibility Results page and will find UQHP and Non-MAGI Medicaid text$/) do
  expect(page.has_css?(IvlIapEligibilityResults.eligibility_results)).to eq true
  expect(page.has_css?(IvlIapEligibilityResults.tax_household)).to eq true
  expect(page.has_css?(IvlIapEligibilityResults.uqhp_heading)).to eq true
  expect(page.has_css?(IvlIapEligibilityResults.uqhp_text)).to eq true
  expect(page.has_css?(IvlIapEligibilityResults.non_magi_referral_heading)).to eq true
  expect(page.has_css?(IvlIapEligibilityResults.non_magi_referral_text)).to eq true
  expect(page.has_css?(IvlIapEligibilityResults.next_steps)).to eq true
  expect(page.has_css?(IvlIapEligibilityResults.next_steps_text)).to eq true
  expect(page.has_css?(IvlIapEligibilityResults.continue_text)).to eq false
  expect(page.has_css?(IvlIapEligibilityResults.return_to_account_home)).to eq true
  expect(page.has_css?(IvlIapEligibilityResults.your_application_reference_2)).to eq true
end

And(/^the application has applicant with ineligible determination$/) do
  setup_applicant_eligible_for_ineligible_determination(application)
end

Then(/^the user will navigate to the Eligibility Results page and will find Ineligibility text$/) do
  expect(page.has_css?(IvlIapEligibilityResults.eligibility_results)).to eq true
  expect(page.has_css?(IvlIapEligibilityResults.tax_household)).to eq true
  expect(page.has_css?(IvlIapEligibilityResults.totally_ineligible_heading)).to eq true
  expect(page.has_css?(IvlIapEligibilityResults.totally_ineligible_text)).to eq true
  expect(page.has_css?(IvlIapEligibilityResults.next_steps)).to eq true
  expect(page.has_css?(IvlIapEligibilityResults.next_steps_text)).to eq true
  expect(page.has_css?(IvlIapEligibilityResults.continue_text)).to eq false
  expect(page.has_css?(IvlIapEligibilityResults.return_to_account_home)).to eq true
  expect(page.has_css?(IvlIapEligibilityResults.your_application_reference_2)).to eq true
end

And(/^the application has non-applicants with no determination$/) do
  setup_non_applicants_with_no_determination(application)
end

Then(/^the user will navigate to the Eligibility Results page and should not see tax household heading$/) do
  expect(page.has_css?(IvlIapEligibilityResults.tax_household)).to eq false
end
