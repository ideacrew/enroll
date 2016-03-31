module VerificationUser
  def user(*traits)
    attributes = traits.extract_options!
    @user ||= FactoryGirl.create :user, *traits, attributes
  end
end
World(VerificationUser)

Then(/^Individual click continue button$/) do
  click_button "CONTINUE"
end

Then(/^I should see verification outstanding label$/) do
  expect(page).to have_content "outstanding"
end

When(/^I click on verification link$/) do
  click_link "Verification"
end

Given(/^I should see page for documents verification$/) do
  expect(page).to have_content "Verification due date"
  expect(page).to have_selector('table tr')
end

Given(/^I upload the file as vlp document$/) do
  within('div.SSN') do
    attach_file('file[]', Rails.root.join('app', 'assets', 'images', 'logo', 'carefirst.jpg'))
  end
end

Given(/^I click the upload file button$/) do
  within('div.SSN2') do
    click_button "Upload"
  end
end

Given(/^a consumer exists$/) do
  user :with_consumer_role
end

Given(/^the consumer is logged in$/) do
  login_as user

end

When(/^the consumer visits verification page$/) do
  visit verification_insured_families_path
  click_link 'Verification'
end

When(/^the consumer should see documents verification page$/) do
  expect(page).to have_content "Verification due date"
  expect(page).to have_selector('table tr')
end

Then(/^the consumer can expand the table by clicking on caret sign$/) do
  find('.fa-caret-down').click
end



