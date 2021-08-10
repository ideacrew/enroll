# frozen_string_literal: true

And(/the user visits the HBX home page?/) do
  visit '/'
  page.execute_script "window.scrollBy(0,10000)"
end

Then(/^they should see the contact email address$/) do
  expect(page).to have_content("info@dchealthlink.com")
end

Then(/^they should not see the contact email address$/) do
  expect(page).to_not have_content("info@dchealthlink.com")
end
