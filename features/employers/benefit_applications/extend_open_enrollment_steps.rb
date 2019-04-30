Then(/^the table will expand displaying the Extend Open Enrollment table$/) do
  expect(page).to have_css('#extendable_applications_table')
  expect(page).to have_css('h4.heading-text', text: 'Extend Open Enrollment')
end

Then(/^the Choose New Open Enrollment Date panel is presented$/) do
  expect(page).to have_css('.edit_open_enrollment_fields')
  find('input[value="Extend Open Enrollment"]')
end

Then(/^a Successfully extended employer\(s\) open enrollment success message will display\.$/) do
  expect(page).to have_css('.alert.alert-success', text: 'Successfully extended employer(s) open enrollment.')
end
