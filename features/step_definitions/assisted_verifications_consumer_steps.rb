Given(/^a consumer, with a family, and consumer_role exists$/) do
  consumer :with_consumer_role
  login_as consumer, scope: :user
  visit financial_assistance_applications_path
  create_plan
  create_hbx_profile
  application
end

Given(/^that a family has a Financial Assistance application in the submitted state$/) do
  application.update_attributes(:assistance_year => TimeKeeper.date_of_record.year)
  application.update_attributes(:aasm_state => 'submitted')
end

Given(/^that a family has submitted a financial assistance application$/) do
  visit financial_assistance_applications_path
end

When(/^an eligibility determination is returned to EA from Haven$/) do
  create_eligibility_determination
  expect(application.all_aptc_applicants.present?).to be_truthy
end

When(/^Haven transmits the response to EA$/) do
  assisted_verifications_response
  expect(application.has_all_verified_applicants?).to be_truthy
end

Then(/^the user will be able to navigate to the Documents page of the account to take actions\.$/) do
  visit  verification_insured_families_path
  click_link 'Documents'
end

When(/^Haven transmits the an "([^"]*)" response to EA for any given member$/) do |arg1|
  create_assisted_verifications
  expect(application.applicants.first.assisted_verifications.first.status).to eq arg1
end

Then(/^Income type will display an "([^"]*)" verification status$/) do |arg1|
  visit  verification_insured_families_path
  click_link 'Documents'
end

Then(/^MEC type will display an "([^"]*)" verification status$/) do |arg1|
  visit  verification_insured_families_path
  click_link 'Documents'
end
