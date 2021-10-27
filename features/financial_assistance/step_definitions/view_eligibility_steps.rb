# frozen_string_literal: true

Given(/^that a user with a family has a Financial Assistance application in the "draft" state$/) do
  login_as consumer, scope: :user
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
  visit financial_assistance.applications_path
  create_plan
  application(aasm_state: "draft")
  application.submit!
  expect(application.complete?).to eq(true)
end

And(/^a user with a family with three dependents has a Financial Assistance application exists$/) do
  login_as consumer, scope: :user
  primary_family = consumer.person.primary_family
  primary_person = consumer.person
  primary_person.ensure_relationship_with(primary_person, 'self')
  3.times do
    params = {
      dependent: {
        first_name: FFaker::Name.send("first_name_male") + (1..100).to_a.sample.to_s,
        last_name: primary_person.last_name,
        dob: "2015-01-01",
        ssn: SecureRandom.hex(100).tr('^0-9', '')[0..8].to_s,
        family_id: primary_family.id,
        gender: 'male',
        relationship: 'child'
      }
    }
    family_member = ::Forms::FamilyMember.new(params[:dependent])
    family_member.save
  end
  primary_family.reload
  expect(primary_family.family_members.count > 1).to eq(true)
  visit financial_assistance.applications_path
  create_plan
  current_application = application
  binding.irb
  expect(current_application.applicants.count > 1).to eq(true)
end

When(/^clicks the "Action" dropdown corresponding to the "submitted" application$/) do
  find_button('Actions').visible?
  click_button('Actions')
end

Given(/^that a user with a family has a Financial Assistance application in the "determination_response_error" state$/) do
  login_as consumer, scope: :user
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
  # binding.irb
  expect(page).to have_content('Eligibility Results')
end

Given(/^that a user with a family has a Financial Assistance application with tax households$/) do
  login_as consumer, scope: :user
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
