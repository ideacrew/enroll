# frozen_string_literal: true

Given(/drop_enrollment_members feature is enabled/) do
  EnrollRegistry[:drop_enrollment_members].feature.stub(:is_enabled).and_return(true)
end

Given(/^User with multiple member enrollment exists$/) do
  create_multiple_member_enrollment_for_family_with_one_minor
end

When(/^Hbx Admin clicks on the Drop Enrollment Members button$/) do
  find_link(l10n('admin_actions.drop_enrollment_members')).click
end

When(/Admin sets termination date for dropped members/) do
  # format: MM/DD/YYYY
  find(DropEnrollmentMembers.drop_enrollment_members_termination_date).click.set((TimeKeeper.date_of_record - 1.day).to_s)
  find(DropEnrollmentMembers.drop_enrollment_members_title).click
end

When(/Admin sets invalid termination date for dropped members/) do
  # format: MM/DD/YYYY
  find(DropEnrollmentMembers.drop_enrollment_members_termination_date).click.set((TimeKeeper.date_of_record - 2.years).to_s)
  find(DropEnrollmentMembers.drop_enrollment_members_title).click
end

When(/Admin selects member to be dropped from enrollment/) do
  find_all(DropEnrollmentMembers.drop_member_select_checkbox).first.click
end

When(/Admin selects members to be dropped from enrollment/) do
  find_all(DropEnrollmentMembers.drop_member_select_checkbox).first.click
  find_all(DropEnrollmentMembers.drop_member_select_checkbox).last.click
end

When(/Admin selects all members except a minor to be dropped from enrollment/) do
  find_all(DropEnrollmentMembers.drop_member_select_checkbox).first.click
  find_all(DropEnrollmentMembers.drop_member_select_checkbox)[1].click
end

When(/Admin submits drop enrollment member form/) do
  find(DropEnrollmentMembers.drop_enrollment_members_submit).click
end

# Submission Results
Then(/Admin should see the dropped members/) do
  expect(page.has_css?(DropEnrollmentMembers.dropped_members_success)).to eq true
end

Then(/Admin should see that the enrollment failed to terminate/) do
  expect(page.has_css?(DropEnrollmentMembers.failed_to_drop_members)).to eq true
end

Then(/Admin should see that no members were selected to be dropped/) do
  expect(page.has_css?(DropEnrollmentMembers.none_selected)).to eq true
end
