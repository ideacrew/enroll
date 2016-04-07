module BinderTransitionWorld
  include ApplicationHelper

  def hbx_admin(*traits)
    attributes = traits.extract_options!
    @hbx_admin ||= FactoryGirl.create :user, *traits, attributes
  end

  def employer(*traits)
    attributes = traits.extract_options!
    @employer ||= FactoryGirl.create :employer, *traits, attributes
  end
end
World(BinderTransitionWorld)

Given(/^an HBX admin exists$/) do
  hbx_admin :with_family, :hbx_staff
end

Given(/^a new employer, with insured employees, exists$/) do
  employer :with_insured_employees
end

Given(/^the HBX admin is logged in$/) do
  login_as hbx_admin, scope: :user
end

Given(/^the HBX admin visits the Dashboard page$/) do
  visit exchanges_hbx_profiles_root_path
  page.find('.interaction-click-control-binder-transition').click
  page.find(".title-inline").should have_content("Binder Transition Information")
end

Then(/^the HBX admin sees a checklist$/) do |checklist|
  expect(page.find(".eligibility-rule").text).to eq eligiblity_participation_rule(employer.employer_profile.show_plan_year.additional_required_participants_count)
end

When(/^the HBX admin selects the employer to confirm$/) do
  sleep 1
  page.find("#employer_profile_id_#{employer.employer_profile.id.to_s}").click
end

Then(/^the initiate "([^"]*)" button will be active$/) do |arg1|
  expect(find("#binderSubmit")["disabled"]).to eq false # binder paid button should be enabled at this point as we selected an employer
end

And(/^the HBX admin clicks the "([^"]*)" button$/) do |arg1|
  click_button arg1
  sleep 1
end

Then(/^then the Employer’s state transitions to "([^"]*)"$/) do |arg1|
  employer.reload
  expect(employer.employer_profile.aasm_state.titleize).to eq arg1
end

Given(/^the employer meets requirements$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Given(/^the HBX admin has confirmed requirements for the employer$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

When(/^the employer remits initial binder payment$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

When(/^the DCHBX confirms binder payment has been received by third\-party processor$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

When(/^the HBX admin has verified new \(initial\) Employer meets minimum participation requirements \((\d+)\/(\d+) rule\)$/) do |arg1, arg2|
  pending # Write code here that turns the phrase above into concrete actions
end

When(/^a sufficient number of 'non\-owner' employee\(s\) have enrolled and\/or waived in Employer\-sponsored benefits$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Given(/^the employer has remitted the initial binder payment$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

When(/^the HBX admin visits the page$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

# When(/^the HBX admin clicks the "([^"]*)" button$/) do |arg1|
#   pending # Write code here that turns the phrase above into concrete actions
# end

Then(/^the Group XML is generated for the Employer$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Given(/^the employer is renewing$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

When(/^the HBX admin visits the last other blank page$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

When(/^the HBX admin visits the other blank page$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^the HBX\-Admin can utilize the “Transmit EDI” button$/) do
  pending # Write code here that turns the phrase above into concrete actions
end
