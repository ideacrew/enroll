# frozen_string_literal: true

Given(/^a consumer exists without coverage$/) do
  user :with_consumer_role
  user.primary_family.family_members.find(&:is_primary_applicant).update_attributes!(is_coverage_applicant: false)
end

When(/^Hbx Admin clicks on Create Eligibility$/) do
  find_link('Create Eligibility').click
end

And(/^Hbx Admin select CSR 100$/) do
  find(:css, '.select_person_csr select').find(:option, '100').select_option
end

And(/^Hbx Admin select tax group one$/) do
  find(:css, 'td.select_person_tax_group select').find(:option, '1').select_option
end

And(/^Hbx Admin click Continue To Tax Group Details$/) do
  find_button('Continue To Tax Group Details').click
end

And(/^Hbx Admin choose Effective Date$/) do
  find('input.date-picker').set((TimeKeeper.date_of_record - 1.days).to_s)
end

And(/^Hbx Admin set Expected Contribution$/) do
  find('input#tax_household_group_tax_households_0_monthly_expected_contribution').set(100)
end

When(/^Hbx Admin click Save Changes$/) do
  find_button('Save Changes').click
end

Then(/^Hbx Admin see successful message$/) do
  expect(page).to have_content("THH & Eligibility created successfully")
end

Then(/^Hbx Admin see error message$/) do
  expect(page).to have_content("Error: The Create Eligibility tool cannot be used because the consumer is not applying for coverage.")
end


