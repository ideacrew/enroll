# frozen_string_literal: true

And(/the user visits the HBX home page?/) do
  visit '/'
  page.execute_script "window.scrollBy(0,10000)"
end

Then(/^they should see the contact email address$/) do
  expect(page).to have_content(EnrollRegistry[:enroll_app].setting(:mail_address).item)
end

Then(/^they should not see the contact email address$/) do
  expect(page).to_not have_content(EnrollRegistry[:enroll_app].setting(:mail_address).item)
end
