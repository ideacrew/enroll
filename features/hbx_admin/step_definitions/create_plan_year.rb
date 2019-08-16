# frozen_string_literal: true

And(/^Hbx Admin should see the list of employer accounts and an Action button$/) do
  within('.effective-datatable') do
    expect(page).to have_css('.dropdown-toggle', count: 2)
  end
end

Given('the user has clicked the Create Plan Year button') do
  find('.btn',text: 'Create Plan Year').click
end

Given('the user has a valid input for all required fields') do
  find('#baStartDate > option:nth-child(2)').click
  find('#fteCount').fill_in :with => '20'
  find('label',:text => 'Open Enrollment End Date').click
end

When(/the admin clicks (.*)$/) do |btn|
  find('.btn', :text => btn).click
end

Then('the user will see a success message') do
  expect(page).to have_content('Successfully created a draft plan year')
end

Then('the draft application will be created') do
  expect(page).to have_content('Plan Year (Draft)')
end

Then(/the existing applications for ABC Widgets will be (.*)$/) do |state|
  expect(page).to have_content("Plan Year (#{state})")
end

Then('the user will see a pop up modal with "Confirm" or "Cancel" action') do
  expect(page).to have_content('Confirm Create Plan Year')
end

Then('the existing application will remain in Publish Pending') do
  expect(page).to have_content('Plan Year (Publish Pending)')
end

Then('the new plan year will NOT be created.') do
  expect(page).to_not have_content('Plan Year (Draft)')
end