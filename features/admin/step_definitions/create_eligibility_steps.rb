Then(/^Hbx Admin should see a Create Eligibility link$/) do
  find_link('Create Eligibility').visible?
end

Then(/^Hbx Admin clicks on the Create Eligibility button$/) do
  find_link('Create Eligibility').click
end

Then(/Hbx Admin should see tax household member level csr select/) do
  expect(find_all(CreateEligibility.thm_csr_select).length).to be > 0
end
