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
