# frozen_string_literal: true

And(/^consumer clicks on pencil symbol next to primary person$/) do
  page.all('.fa-pencil-alt').first.click
end

Then(/^consumer should see today date and clicks continue$/) do
  expect(page).to have_field('applicant_ssn', readonly: true)
  expect(page.find("input[name='jq_datepicker_ignore_applicant[dob]'")[:disabled]).to eq "true"
end

Given(/eligible immigration status checkbox feature is enabled/) do
  enable_feature :immigration_status_checkbox
end

And(/consumer chooses no for us citizen/) do
  find(IvlIapFamilyInformation.us_citizen_or_national_no_radiobtn).click
end

Then(/consumer should see the eligible immigration status checkbox/) do
  expect(page.find('#applicant_eligible_immigration_status')).to be_truthy
end
