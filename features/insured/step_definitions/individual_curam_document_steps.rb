
When(/^the user navigates to the DOCUMENTS tab$/) do
  visit verification_insured_families_path
end

When(/^MEDICAID & TAX CREDITS button is visible to the user$/) do
  find(IvlDocumentsPage.medicare_and_tax_credit_btn, wait: 5).visible?
end

Then(/^there will be text to the left of the MEDICAID & TAX CREDITS button$/) do
  expect(page).to have_css(AdminHomepage.medicaid_banner_text)
end

Then(/^EA sets a flag in IAM to direct the consumer to the curam\/ drupal login$/) do
  expect(page).to have_content(EnrollRegistry[:enroll_app].setting(:mail_address).item)
end

When(/^selects a Person account and navigates to Verification page$/) do
  @person = FactoryBot.create(:person, :with_consumer_role)
  visit verification_insured_families_path
end

And(/^the broker sees the documents tab$/) do
  find('.interaction-click-control-documents').visible?
end

When(/^the broker visits verification page$/) do
  # sleep 100
  visit verification_insured_families_path
  # visit verification_insured_families_path(tab: 'verification')
  # find(".interaction-click-control-documents", wait: 5).click
end

When(/^the user visits messages page$/) do
  visit inbox_insured_families_path
end

When(/^the user visits the applications page$/) do
  visit financial_assistance.applications_path
end

When(/^selects a Person account and navigates to Messages page$/) do
  @person = FactoryBot.create(:person, :with_consumer_role)
  visit inbox_insured_families_path
end
