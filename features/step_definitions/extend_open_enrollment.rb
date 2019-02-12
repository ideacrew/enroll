When(/^the Hbx Admin clicks Extend Open Enrollment$/) do
	find('.btn.btn-xs', text: 'Extend Open Enrollment').click
end

When(/^the Hbx Admin clicks Edit Open Enrollment$/) do
  find('a.btn.btn-primary.btn-sm', text: 'EDIT OPEN ENROLLMENT').trigger('click')
end

Then(/^the Choose New Open Enrollment Date panel is presented$/) do
  expect(page).to have_css('.edit_open_enrollment_fields')
  find('input[value="Extend Open Enrollment"]')
end

Then(/^the Hbx Admin enters a new open enrollment end date$/) do
  input = find('input.hasDatepicker')
  input.set(Date.today+1.week)
end

Then(/^the Hbx Admin clicks Extend Open Enrollment button$/) do
  find('input[value="Extend Open Enrollment"]').trigger('click')
end

Then(/^a Successfully extended employer\(s\) open enrollment success message will display\.$/) do
  expect(page).to have_css('.alert.alert-success', text: 'Successfully extended employer(s) open enrollment.')
end
