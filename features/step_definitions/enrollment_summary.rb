# frozen_string_literal: true

When(/^consumer clicks on the View my coverage details$/) do
  create_qhp
  page.execute_script("document.querySelector('#view-details-btn').click()")
  sleep(4)
end

Then(/^additional Enrollment Summary exists$/) do
  sleep(3)
  expect(page.has_css?(IvlHomepage.enrollment_tobacco_use)).to eq true
  expect(page.has_css?(IvlHomepage.enrollment_coverage_state_date)).to eq true
  expect(page.has_css?(IvlHomepage.enrollment_detail)).to eq true
  expect(page.has_css?(IvlHomepage.enrollment_member_detail)).to eq true
end

Given(/^the display enrollment summary configuration is enabled$/) do
  enable_feature :display_enr_summary
end
