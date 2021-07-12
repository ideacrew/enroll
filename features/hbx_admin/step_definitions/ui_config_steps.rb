# frozen_string_literal: true

Given(/issuers feature is enabled?/) do
  enable_feature(:issuers_tab)
end

Given(/issuers feature is disabled?/) do
  disable_feature(:issuers_tab)
end

Then(/^they should see the Issuers tab$/) do
  expect(page).to have_content("Issuers")
end

Then(/^they should not see the Issuers tab$/) do
  expect(page).to_not have_content("Issuers")
end

Given(/inbox feature is enabled?/) do
  enable_feature(:inbox_tab)
end

Given(/inbox feature is disabled?/) do
  disable_feature(:inbox_tab)
end

Then(/^they should see the Inbox tab$/) do
  expect(page).to have_content("Inbox")
end

Then(/^they should not see the Inbox tab$/) do
  expect(page).to_not have_content("Inbox")
end


