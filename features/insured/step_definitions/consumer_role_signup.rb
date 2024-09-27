Given(/^user signup$/) do
  visit "/users/sign_up"
  fill_in "user_oim_id", with: user_sign_up[:oim_id]
  fill_in "user_password", with: user_sign_up[:password]
  fill_in "user_password_confirmation", with: user_sign_up[:password_confirmation]
end

When(/^user clicks inside the email field$/) do
  find('#user_email').click
end

And(/^user clicks outside the email field$/) do
  find('body').click
end

Then(/^user should not see the error message$/) do
  expect(page).not_to have_content('Invalid Email Entered xxx')
end
