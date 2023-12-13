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

Given(/inbox feature is disabled?/) do
  disable_feature(:inbox_tab)
end

Then(/^they should see the Inbox tab$/) do
  expect(page).to have_content("Inbox")
end

Then(/^they should not see the Inbox tab$/) do
  expect(page).to_not have_content("Inbox")
end

And(/calendar feature is enabled?/) do
  enable_feature(:calendar_tab)
end

And(/calendar feature is disabled?/) do
  disable_feature(:calendar_tab)
end

Then(/^they should see the Calendar tab$/) do
  expect(page).to have_content("Calendar")
end

Then(/^they should not see the Calendar tab$/) do
  expect(page).to_not have_content("Calendar")
end

When(/^the user types in the calendar URL$/) do
  visit "/exchanges/scheduled_events"
end

Then(/^the user will not be able to access calendar page$/) do
  expect(page).to_not have_content("Create Event")
  expect(page).to have_content(l10n("calendar_not_enabled"))
end

Then(/^the user will be able to access calendar page$/) do
  expect(page).to have_content("Create Event")
end

And(/staff feature is enabled?/) do
  enable_feature(:staff_tab)
end

When(/^the user types in the staff index URL$/) do
  visit "/exchanges/hbx_profiles/staff_index"
end

Then(/^the user will not be able to access staff index page$/) do
  expect(page).to_not have_content("CSR, CAC and Assisters")
  expect(page).to have_content(l10n("staff_index_not_enabled"))
end

Then(/^the user will be able to access staff index page$/) do
  expect(page).to have_content("CSR, CAC and Assisters")
end

When(/^the user types in the orphan accounts URL$/) do
  visit "/users/orphans"
end

Then(/^the user will not be able to access orphan accounts page$/) do
  expect(page).to_not have_content("Orphan User Accounts")
  expect(page).to have_content(l10n("orphan_accounts_not_enabled"))
end

Then(/access will be denied for the user/) do
  expect(page).to have_content("Access not allowed")
end

Then(/the user clicks on Orphan User Accounts/) do
  page.find('#users-orphans').click
end

Then(/^the user will be able to access orphan accounts page$/) do
  expect(page).to have_content("Orphan User Accounts")
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

And(/contrast_level_aa feature is enabled?/) do
  # Assets are compiled for DC environment. Because of this, we need to reload the page
  # in order to test our AA compliant styling changes for ME.
  ENV["CONTRAST_LEVEL_AA_IS_ENABLED"] = "true"
  page.reset!
end
