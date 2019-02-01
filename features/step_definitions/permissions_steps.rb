When(/^Hbx Admin clicks on Employers link$/) do
	click_link 'Employers'
end

Then(/^Hbx Admin should see an Force Publish button$/) do
  expect(page).to have_content("Force Publish")
end

When(/^Hbx Admin should not see an Force Publish button$/) do
	expect(page).not_to have_content("Force Publish")
end