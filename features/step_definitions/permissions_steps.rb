When(/^Hbx Admin clicks on Employers link$/) do
	click_link 'Employers'
end

Then(/^Hbx Admin should see an Extend Open Enrollment button$/) do
  expect(page).to have_content("Extend Open Enrollment")
end

When(/^Hbx Admin should not see an Extend Open Enrollment button$/) do
	expect(page).not_to have_content("Extend Open Enrollment")
end