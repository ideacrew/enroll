# frozen_string_literal: true

Given(/no transition families feature is enabled?/) do
  enable_feature(:no_transition_families)
end

Given(/no transition families feature is disabled?/) do
  disable_feature(:no_transition_families)
end

And(/^the user clicks the Families tab$/) do
  page.find('.interaction-click-control-families').click
end

Then(/^they should see the Resident Application Link$/) do
  expect(page).to have_content("Resident Application")
end

Then(/^they should not see the Resident Application Link$/) do
  expect(page).to_not have_content("Resident Application")
end

And(/^the user clicks the Families link$/) do
  click_link 'Families'
end

And(/^the user clicks the Actions tab$/) do
  page.find('button', :text => 'Actions').click
end

And(/^the user navigates to the resident applications url$/) do
  visit "/exchanges/residents/search"
end

Then(/^they should be redirected to the welcome page$/) do
  expect(page).to have_content("Resident Application Link Is Disabled")
end

Then(/^they should see the Transition Family Members Link$/) do
  expect(page).to have_content("Transition Family Members")
end

Then(/^they should not see the Transition Family Members Link$/) do
  expect(page).to_not have_content("Transition Family Members")
end
