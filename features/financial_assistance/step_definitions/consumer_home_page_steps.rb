
When(/^a consumer visits the home page$/) do
  visit "/families/home?tab=home"
end

Given(/medicaid tax credits link is enabled?/) do
  enable_feature(:medicaid_tax_credits_link)
end

Given(/medicaid tax credits link is disabled?/) do
  disable_feature(:medicaid_tax_credits_link)
end

Then(/^they should see the medicaid and tax credits link tile$/) do
  expect(page).to have_content("Medicaid & Tax Credits")
end

Then(/^they should not see the medicaid and tax credits link tile$/) do
  expect(page).to_not have_content("Medicaid & Tax Credits")
end






