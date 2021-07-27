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

Given(/notices feature is enabled?/) do
  enable_feature(:notices_tab)
end

Given(/notices feature is disabled?/) do
  disable_feature(:notices_tab)
end

Then(/^they should see the Notices tab$/) do
  expect(page).to have_content("Notices")
end

Then(/^they should not see the Notices tab$/) do
  expect(page).to_not have_content("Notices")
end

Given(/calendar feature is enabled?/) do
  enable_feature(:calendar_tab)
end

Given(/calendar feature is disabled?/) do
  disable_feature(:calendar_tab)
end

Then(/^they should see the Calendar tab$/) do
  expect(page).to have_content("Calendar")
end

Then(/^they should not see the Calendar tab$/) do
  expect(page).to_not have_content("Calendar")
end

Given(/staff feature is enabled?/) do
  enable_feature(:staff_tab)
end

Given(/staff feature is disabled?/) do
  disable_feature(:staff_tab)
end

Then(/^they should see the Staff tab$/) do
  expect(page).to have_content("Staff")
end


Then(/^they should not see the Staff tab$/) do
  expect(page).to_not have_content("Staff")
end

Given(/orphan accounts feature is enabled?/) do
  enable_feature(:orphan_accounts_tab)
end

Given(/orphan accounts feature is disabled?/) do
  disable_feature(:orphan_accounts_tab)
end

Then(/^they should see the Orphan Accounts tab$/) do
  expect(page).to have_content("Orphan Accounts")
end


Then(/^they should not see the Orphan Accounts tab$/) do
  expect(page).to_not have_content("Orphan Accounts")
end

And(/^the user clicks the Admin tab$/) do
  page.find('.dropdown-toggle', text: 'Admin').click
end
