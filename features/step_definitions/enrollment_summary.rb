# frozen_string_literal: true

When(/^\w+ clicks on the View my coverage details$/) do
  create_qhp
  page.execute_script("document.querySelector('#view-details-btn').click()")
  sleep(4)
end

Then(/^additional Enrollment Summary exists$/) do
  sleep(3)
  expect(page.has_css?(IvlHomepage.enrollment_tobacco_use)).to eq true
  expect(page.has_css?(IvlHomepage.enrollment_coverage_state_date)).to eq true
  expect(page).to have_content("Enrollment Detail")
  expect(page.has_css?(IvlHomepage.enrollment_member_detail)).to eq true
end

Then(/^additional Enrollment Summary does not exists$/) do
  sleep(3)
  expect(page.has_css?(IvlHomepage.enrollment_tobacco_use)).to eq false
  expect(page.has_css?(IvlHomepage.enrollment_coverage_state_date)).to eq false
  expect(page.has_css?(IvlHomepage.enrollment_detail)).to eq false
  expect(page.has_css?(IvlHomepage.enrollment_member_detail)).to eq false
end

Given(/^the display enrollment summary configuration is enabled$/) do
  enable_feature :display_enr_summary
end

And(/^navigates to Enrollment Summary page$/) do
  sleep(3)
  expect(page).to have_content(l10n('enrollment.details.header'))
end

Then(/^the \w+ should see "(.*)" text$/) do |label|
  expect(page).to have_content(label)
end
