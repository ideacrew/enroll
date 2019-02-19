Then(/^Hbx Admin should see an Close Open Enrollment button$/) do
	expect(page).to have_content("Close Open Enrollment")
end

Then(/^Hbx Admin should not see an Close Open Enrollment button$/) do
	expect(page).not_to have_content("Close Open Enrollment")
end

When(/^the Hbx Admin clicks Close Open Enrollment$/) do
	find('.btn.btn-xs', text: 'Close Open Enrollment').click
end

When(/^the Hbx Admin clicks Close Open Enrollment button$/) do
  find('a.btn.btn-primary.btn-sm', text: 'CLOSE OPEN ENROLLMENT').trigger('click')
end

Then(/^a Successfully closed employer\(s\) open enrollment success message will display\.$/) do
	expect(page).to have_css('.alert.alert-success', text: 'Successfully closed employer(s) open enrollment.')
end