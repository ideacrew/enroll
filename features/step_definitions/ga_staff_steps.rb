When(/^GA staff enters his personal information$/) do
  find('a', :text => "General Agency Staff", wait: 5).click
  fill_in 'staff[first_name]', with: 'Ricky'
  fill_in 'staff[last_name]', with: 'Martin'
  fill_in 'staff[dob]', with: '10/10/1984'
  find('#inputEmail').click
  fill_in 'staff[email]', with: 'ricky.martin@example.com'
end

Then(/^GA Staff should see the General Agency Staff Registration form$/) do
  find('#general_agency_form', wait: 10)
  expect(page).to have_css("#general_agency_form")
end

When(/^GA staff searches for General Agency which exists in EA$/) do
  find('#staff_agency_search').click
  fill_in 'staff_agency_search', with: general_agency_profile.legal_name
  find('.search').click
end

When(/^GA staff should see a list of General Agencies searched and selects his agency$/) do
  find('.select-general-agency', wait: 10).click
end

Then(/^GA staff submits his application and see successful message$/) do
  expect(page).to have_button('Submit', disabled: false)
  find('#general-agency-staff-btn').click
  expect(page).to have_content('Your registration has been submitted. A response will be sent to the email address you provided once your application is reviewed.')
end

And(/^there is a Staff with a “pending” general agency staff role in the table$/) do
  #find('a', :text => "Broker Agency Portal", wait: 5).click
  expect(page).to have_content('approve')
  expect(page).to have_content('General Agency Staff')
  expect(page).to have_content('Ricky')
end

When(/^the primary staff clicks on the approve button$/) do
  page.execute_script("document.querySelector('.approve').click()")
end

Then(/^the primary staff should see the staff successfully approved message$/) do
  expect(page).to have_content('Role approved successfully')
end

When(/^the primary staff removes ga staff from ga staff table$/) do
  page.execute_script("document.querySelector('#destroy').click()")
end

Then(/^the primary staff should see the staff successfully removed message$/) do
  expect(page).to have_content('Role removed successfully')
end

Then /^new ga staff should receive an email$/ do
  staff = general_agency_organization.general_agency_profile.general_agency_staff_roles.last
  open_email(staff.email_address)
end

When /^new ga staff visits the link received in the approval email$/ do
  staff = general_agency_organization.general_agency_profile.general_agency_staff_roles.last
  email_address = staff.email_address

  open_email(email_address)
  expect(current_email.to).to eq([email_address])

  invitation_link = links_in_email(current_email).first
  invitation_link.sub!(/http\:\/\/127\.0\.0\.1\:3000/, '')
  visit(invitation_link)
end

When /^new ga staff completes the account creation form and hit the 'Submit' button$/ do
  email_address = general_agency_organization.general_agency_profile.general_agency_staff_roles.last.email_address
  fill_in "user[oim_id]", with: email_address
  fill_in "user[password]", with: "aA1!aA1!aA1!"
  fill_in "user[password_confirmation]", with: "aA1!aA1!aA1!"
  find('.create-account-btn', wait: 10).click
end
