#frozen_string_literal: true

Given(/medicaid tax credits link feature is enabled?/) do
  enable_feature(:medicaid_tax_credits_link)
end

Given(/medicaid tax credits link feature is disabled?/) do
  disable_feature(:medicaid_tax_credits_link)
end

And(/^the consumer navigates to the (.*?) page$/) do |page|
  expect(page).to have_content(page)
end

Then(/^they should see the Medicaid and Tax Credits Link tile$/) do
  expect(page).to have_content(AdminHomepage.medicaid_button_text)
  expect(page).to have_css(IvlHomepage.medicaid_and_tax_credits_btn)
end

Then(/^they should not see the Medicaid and Tax Credits Link tile$/) do
  expect(page).to_not have_content(AdminHomepage.medicaid_button_text)
  expect(page).to_not have_css(IvlHomepage.medicaid_and_tax_credits_btn)
end

Then(/^they should see the Medicaid and Tax Credits text$/) do
  expect(page).to have_content(AdminHomepage.medicaid_banner_text)
end

Then(/^they should not see the Medicaid and Tax Credits text$/) do
  expect(page).to_not have_content(AdminHomepage.medicaid_banner_text)
end

Given(/consumer visits enroll app home page?/) do
  visit '/'
end

Then(/^they should see the Assisted Consumer Family Portal tile$/) do
  expect(page).to have_content("Assisted Consumer")
end

Then(/^they should not see the Assisted Consumer Family Portal tile$/) do
  expect(page).to_not have_content("Assisted Consumer")
end

Given(/consumer visits the privacy notice page?/) do
  visit '/insured/consumer_role/privacy?aqhp=true'
end

Then(/^they should be redirected to the enroll app home page$/) do
  expect(page).to have_content("Medicaid And Tax Credits Link Is Disabled")
end
