# frozen_string_literal: true

Given(/email address feature is enabled?/) do
  enable_feature(:contact_email_feature)
end

Given(/email address feature is disabled?/) do
  disable_feature(:contact_email_feature)
end

And(/the user visits the HBX home page?/) do
  visit '/'
  page.execute_script "window.scrollBy(0,10000)"
end

Then(/^they should see the contact email address$/) do
  expect(page).to have_content("info@dchealthlink.com")
end

Then(/^they should not see the contact email address$/) do
  expect(page).to_not have_content("info@dchealthlink.com")
end
