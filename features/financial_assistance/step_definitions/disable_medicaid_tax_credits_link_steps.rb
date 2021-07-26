# frozen_string_literal: true

Given(/medicaid tax credits link feature is enabled?/) do
  enable_feature(:medicaid_tax_credits_link)
end

Given(/medicaid tax credits link feature is disabled?/) do
  disable_feature(:medicaid_tax_credits_link)
end

And(/^the consumer navigates to the (.*?) page$/) do |page|
  expect(page).to have_content(page)
end

And(/^the consumer clicks the (.*?) link$/) do |link|
  expect(link).to have_content(link)
end

Then(/^they should see the Medicaid and Tax Credits Link tile$/) do
  expect(page).to have_content("Medicaid & Tax Credits")
end

Then(/^they should not see the Medicaid and Tax Credits Link tile$/) do
  expect(page).to_not have_content("Medicaid & Tax Credits")
end












