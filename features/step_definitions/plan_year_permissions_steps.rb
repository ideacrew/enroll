When(/^Hbx Admin should see an Create Plan Year button$/) do
  expect(page).to have_content("Create Plan Year")
end

When(/^Hbx Admin should not see an Create Plan Year button$/) do
  expect(page).not_to have_content("Create Plan Year")
end
