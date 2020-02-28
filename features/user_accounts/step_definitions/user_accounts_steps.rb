Given(/^the HBX admin is on the User Accounts page$/) do
  visit '/exchanges/hbx_profiles'
  click_link 'User Accounts'
  expect(page).to have_content('Account Updates')
end

When(/^the HBX admin searches for the given user$/) do
  user = User.where(:'roles'.in => ["employee"], locked_at: nil).first.oim_id
  find("input[type='search']").set(user)
  expect(page).to have_content('Showing 1 to 1 of 1 entries')
end

When(/^the HBX admin selects the Edit User option$/) do
  find(:xpath, '//*[starts-with(@id, "dropdown_for_user_action")]').click
  all('.btn-xs', text: 'Edit User')[0].click
end

Then(/^the HBX Admin will see the Edit User Credentials$/) do
  expect(page).to have_content('Edit User Credentials')
  expect(page).to have_content('New Username')
  expect(page).to have_content('New Email')
end

When(/^the HBX admin updates the username for the user$/) do
  find('#inputNewUsername').set('EmployeeOne')
  find("input[type='submit']").click
end

Then(/^the HBX admin should see the Edit User option$/) do
  find(:xpath, '//*[starts-with(@id, "dropdown_for_user_action")]').click
  expect(page).to have_content('Edit User')
end

Then(/^the HBX admin should receive an success message$/) do
  page.driver.browser.switch_to.alert.accept
  expect(page).to have_content('User Account Updated Successfully')
end

When(/^the HBX admin updates the email for the user$/) do
  find('#inputNewEmail').set('EmployeeOne@test.com')
  find("input[type='submit']").click
end

When(/^the HBX admin updates the email and username for the user$/) do
  find('#inputNewUsername').set('EmployeeOne')
  find('#inputNewEmail').set('EmployeeOne@test.com')
  find("input[type='submit']").click
end

When(/^the HBX admin updates the username with a username already in use$/) do
  @user = User.where(:'roles'.in => ["employer_staff"], locked_at: nil).first
  FactoryGirl.create(:person, user: @user)
  find('#inputNewUsername').set(@user.oim_id)
  find("input[type='submit']").click
end

When(/^the HBX admin updates the email with a email already in use$/) do
  @user = User.where(:'roles'.in => ["employer_staff"], locked_at: nil).first
  FactoryGirl.create(:person, user: @user)
  find('#inputNewEmail').set(@user.email)
  find("input[type='submit']").click
end

Then(/^an error message will appear stating that the credentials are currently in use$/) do
  page.driver.browser.switch_to.alert.accept
  expect(page).to have_content(/The (.*?) matches with the following user:/)
end

Then(/^the error message will contain the First Name, Last Name, and HBX ID of the user that currently has the requested credentials$/) do
  expect(page).to have_content("First Name :#{@user.person.first_name}")
  expect(page).to have_content("Last Name: #{@user.person.last_name}")
  expect(page).to have_content("HBX ID: #{@user.person.hbx_id}")
end

When(/^the HBX admin updates the email and username with a email and username already in use$/) do
  @user = User.where(:'roles'.in => ["employer_staff"], locked_at: nil).first
  FactoryGirl.create(:person, user: @user)
  find('#inputNewEmail').set(@user.email)
  find('#inputNewUsername').set(@user.oim_id)
  find("input[type='submit']").click
end

When(/^the users username and email appear in the form fields$/) do
  user = User.where(:'roles'.in => ["employee"], locked_at: nil).first
  expect(find_field('new_oim_id').value).to eq user.oim_id
  expect(find_field('new_email').value).to eq user.email
end

When(/^the HBX Admin presses the Reset button on the Edit User form$/) do
  find_button("Reset").click
end

Then(/^the text in the username and email address fields will be cleared$/) do
  expect(find_field('new_oim_id').value).to eq ""
  expect(find_field('new_email').value).to eq ""
end

When(/^the HBX admin searches for the given user by first name$/) do
  user = User.where(:'roles'.in => ["employee"], locked_at: nil).first
  person = FactoryGirl.create(:person, user: user)
  find("input[type='search']").set(person.first_name)
end

When(/^the HBX admin searches for the given user by last name$/) do
  user = User.where(:'roles'.in => ["employee"], locked_at: nil).first
  person = FactoryGirl.create(:person, user: user)
  find("input[type='search']").set(person.last_name)
end

When(/^the HBX admin searches for the given user by full name$/) do
  user = User.where(:'roles'.in => ["employee"], locked_at: nil).first
  person = FactoryGirl.create(:person, user: user)
  find("input[type='search']").set("#{person.first_name} #{person.last_name}")
end

When(/^the HBX admin searches for the given user by hbx id$/) do
  user = User.where(:'roles'.in => ["employee"], locked_at: nil).first
  person = FactoryGirl.create(:person, user: user)
  find("input[type='search']").set("#{person.hbx_id}")
end

Then(/^the HBX admin should see the user in the search results$/) do
  expect(page).to have_content(/Showing (.*?) to (.*?) of (.*?) entries/)
end

When(/^the HBX admin searches for the given user by username$/) do
  user = User.where(:'roles'.in => ["employee"], locked_at: nil).first
  find("input[type='search']").set(user.oim_id)
end

When(/^the HBX admin searches for the given user by email$/) do
  user = User.where(:'roles'.in => ["employee"], locked_at: nil).first
  find("input[type='search']").set(user.email)
end
