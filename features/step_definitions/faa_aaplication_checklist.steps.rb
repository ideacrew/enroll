Then(/^the user has navigated to Application checklist page$/) do
  expect(page).to have_content('Gather Income and Coverage Info')
end

Given(/^the user is on the Application checklist page$/) do
  expect(page).to have_content('Application Checklist')
end

When(/^the user clicks on CONTINUE$/) do
  find('.btn', text: 'CONTINUE').click
end

Then(/^the user will navigate to the FAA Household Infor: Family Members page$/) do
  expect(page).to have_content('Household Info: Family Members')
end

Then(/^the user navigates to the Help Paying for Coverage page$/) do
  expect(page).to have_content('Help Paying for Coverage')
end

Then(/^the next time the user logs in the user will see Application checklist page$/) do
  visit "/users/sign_in"
  fill_in "user_login", with: user_sign_up[:oim_id]
  fill_in "user_password", with: user_sign_up[:password]
  click_button "Sign in"
end