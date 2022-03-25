# frozen_string_literal: true

When(/^consumer clicks on the View my coverage details$/) do
  create_qhp
  page.execute_script("document.querySelector('#view-details-btn').click()")
  sleep(4)
end

Then(/^additional Enrollment Summary exists$/) do
  sleep(3)
  expect(page).to have_content(l10n('enrollment.tobbaco_user'))
  expect(page).to have_content(l10n('enrollment_member.coverage_state_date'))
end

Given(/^the display enrollment summary configuration is enabled$/) do
  enable_feature :display_enr_summary
end
