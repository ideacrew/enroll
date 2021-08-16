#frozen_string_literal: true

When(/^the consumer visits the Documents page$/) do
  visit('/insured/families/verification?tab=verification')
end

Then(/^they should see the state residency tile$/) do
  expect(page).to have_content(EnrollRegistry[:enroll_app].setting(:state_residency).item)
end

Then(/^they should not see the state residency tile$/) do
  expect(page).to_not have_content(EnrollRegistry[:enroll_app].setting(:state_residency).item)
end
