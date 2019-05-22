When(/^Broker staff enters his personal information$/) do
  visit "/broker_registration"
  find('a', :text => "Broker Agency Staff", wait: 5).click
  wait_for_ajax(3,4)
  fill_in 'staff[first_name]', with: 'Ricky'
  fill_in 'staff[last_name]', with: 'Martin'
  fill_in 'staff[dob]', with: '10/10/1984'
  find('#inputEmail').click
  fill_in 'staff[email]', with: 'ricky.martin@example.com'
end

Then(/^Broker Staff should see the Broker Staff Registration form$/) do
  wait_for_ajax(3,4)
  expect(page).to have_css("#broker_agency_form")
end

When(/^Broker staff searches for Broker Agency which exists in EA$/) do
  find('#staff_agency_search').click
  fill_in 'staff_agency_search', with: @broker_agency_profile.organization.legal_name
  find('.search').click
end

When(/^Broker staff should see a list of Broker Agencies searched and selects his agency$/) do
  wait_for_ajax
  find('.select-broker-agency').click
end

Then(/^Broker staff submits his application and see successful message$/) do
  expect(page).to have_button('Submit', disabled: false)
  find('#broker-staff-btn').click
  wait_for_ajax
  expect(page).to have_content('Your registration has been submitted. A response will be sent to the email address you provided once your application is reviewed.')
end

Given(/^that a Broker logs into a given (.*)$/) do |portal|
  visit "/"
  find('a', :text => portal.to_s, wait: 5).click
  wait_for_ajax(3,4)
  fill_in "user[login]", :with => @user.oim_id
  fill_in "user[password]", :with => @user.password
  find('.interaction-click-control-sign-in').click
end


And(/^there is a Staff with a “pending” broker staff role in the table$/) do
  #find('a', :text => "Broker Agency Portal", wait: 5).click
  wait_for_ajax(3,4)
  expect(page).to have_content('approve')
  expect(page).to have_content('Broker Agency Staff')
  expect(page).to have_content('Ricky')
end

When(/^the Broker clicks on the approve button$/) do
  page.execute_script("document.querySelector('.approve').click()")
end

Then(/^Broker should see the staff successfully approved message$/) do
  wait_for_ajax(3,4)
  expect(page).to have_content('Role approved successfully')
end

Then(/^Broker Staff should receive an invitation email from his Employer$/) do
  open_email("ricky.martin@example.com", :with_subject => "Invitation to create your Broker Staff account on #{Settings.site.short_name} ")
  expect(current_email.to).to eq(["ricky.martin@example.com"])
end

When(/^the Broker removes Broker staff from Broker staff table$/) do
  page.execute_script("document.querySelector('#destroy').click()")
end

Then(/^Broker should see the staff successfully removed message$/) do
  wait_for_ajax(3,4)
  expect(page).to have_content('Role removed successfully')
end

And(/^the Broker clicks on the “Add Broker Staff Role” button$/) do
  find('.interaction-click-control-add-broker-staff-role').click
end

And(/^a form appears that requires the Broker to input First Name, Last Name, and DOB to submit$/) do
  expect(page).to have_css('#staff_first_name')
  expect(page).to have_css('#staff_last_name')
  expect(page).to have_css('#staff_dob')
end

When(/^the Broker enters the First Name, Last Name, and DOB of an existing user in EA$/) do
  fill_in 'staff[first_name]', with: @person2.first_name
  fill_in 'staff[last_name]', with: @person2.last_name
  fill_in 'staff[dob]', with: @person2.dob
end

Then(/^the Broker will be given a broker staff role with the given Broker Agency$/) do
  find(:xpath, '//*[@id="myTabContent"]/div/form/button').click
end

And(/^the Broker will now appear within the “Broker Staff” table as Active and Linked$/) do
  wait_for_ajax
  expect(page).to have_content('Role added successfully')
  expect(page).to have_content('Active Linked')
end

When(/^the Broker enters the First Name, Last Name, and DOB of an non existing user in EA$/) do
  fill_in 'staff[first_name]', with: 'hello'
  fill_in 'staff[last_name]', with: 'world'
  fill_in 'staff[dob]', with: '10/10/1984'
end

Then(/^the Broker will not be given a broker staff role with the given Broker Agency$/) do
  find(:xpath, '//*[@id="myTabContent"]/div/form/button').click
  wait_for_ajax
  expect(page).to have_content('Role was not added because Person does not exist on the Exchange')
end
