Then(/^Hbx Admin should see an Extend Open Enrollment button$/) do
  expect(page).to have_content("Extend Open Enrollment")
end

When(/^Hbx Admin should not see an Extend Open Enrollment button$/) do
	expect(page).not_to have_content("Extend Open Enrollment")
end