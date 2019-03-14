When(/^the Hbx Admin clicks on Create Plan Year link$/) do
  find('.btn.btn-xs', text: 'Create Plan Year').click
end

Then(/^the Hbx Admin will see the Create Plan Year option row$/) do
  expect(page).to have_css('label', text: 'Effective Start Date')
  expect(page).to have_css('label', text: 'Effective End Date')
  expect(page).to have_css('label', text: 'Full Time Employees')
  expect(page).to have_css('label', text: 'Open Enrollment Start Date')
  expect(page).to have_css('label', text: 'Open Enrollment End Date')
end

Then(/^the Create Plan Year form submit button will be disabled$/) do
  # expect(page.find("#adminCreatePyButton")[:class].include?("disabled")).to eq true
end

When(/^the Hbx Admin clicks the X icon on the Create Plan Year form$/) do
  find(:css, 'i.fa.fa-times.fa-lg').find(:xpath,".//..").trigger('click')
end

Then(/^the Create Plan Year option row will no longer be visible$/) do
  # expect(page).not_to have_css('label', text: 'Effective Start Date')
  # expect(page).not_to have_css('label', text: 'Effective End Date')
  # expect(page).not_to have_css('label', text: 'Full Time Employees')
  # expect(page).not_to have_css('label', text: 'Open Enrollment Start Date')
  # expect(page).not_to have_css('label', text: 'Open Enrollment End Date')
end

Then(/^the Effective End Date for the Create Plan Year form will be blank$/) do
  expect(find('#end_on').value.blank?).to eq true
end

Then(/^the Open Enrollment Start Date for the Create Plan Year form will be disabled$/) do
  expect(page.find("#open_enrollment_start_on")[:class].include?("blocking")).to eq true
end

Then(/^the Open Enrollment End Date for the Create Plan Year form will be disabled$/) do
  expect(page.find("#open_enrollment_end_on")[:class].include?("blocking")).to eq true
end

Then(/^the Hbx Admin selects an Effective Start Date from the Create Plan Year form$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^the Effective End Date for the Create Plan Year form will be filled in$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^the Open Enrollment Start Date for the Create Plan Year form will be enabled$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^the Open Enrollment End Date for the Create Plan Year form will be enabled$/) do
  pending # Write code here that turns the phrase above into concrete actions
end
