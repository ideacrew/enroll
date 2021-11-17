Then(/^Hbx Admin should see the list of primary applicants and an Action button$/) do
  within('.effective-datatable') do
    expect(page).to have_css('.dropdown-toggle', count: 1)
  end
end

When("Hbx Admin clicks Families Link") do
  find('#families', wait: 10).click
end

Then(/^Hbx Admin should see the list of user accounts and an Action button$/) do
  within('.effective-datatable') do
    expect(page).to have_css('.dropdown-toggle', count: 2)
  end
end

# FIXME: Make this take a 'for' argument, that way we can select which user
When(/^Hbx Admin clicks Action button$/) do
  find_all('.dropdown.pull-right', text: 'Actions')[0].click
end

When(/^Hbx Admin click Action button$/) do
  within('.effective-datatable') do
    find_all('.dropdown-toggle', :wait => 10).last.click
  end
end

When(/^Hbx Admin enters an invalid SSN and clicks on update$/) do
  sleep 2
  fill_in AdminFamiliesPage.new_ssn, :with => '212-31-31'
  sleep 2
  page.find_button("Update").click
  sleep 2
  page.driver.browser.switch_to.alert.accept
  sleep 2
end

When(/^Hbx Admin clicks Action for a person on families index page$/) do
  find(AdminFamiliesPage.actions_drop_down_toggle, text: AdminFamiliesPage.actions_drop_down_text).click
end

Given("that a user with a HBX staff role with HBX Staff exists and is logged in") do
  expect(page).to have_css('.btn.btn-xs', text: 'Change FEIN')
end

# FIXME: Make this take a 'for' argument, that way we can select which user
Then(/^Hbx Admin should see an edit DOB\/SSN link$/) do
  find_link('Edit DOB / SSN').visible?
end

# FIXME: Make this take a 'for' argument, that way we can select which user
When(%r{^Hbx Admin clicks on edit DOB/SSN link$}) do
  click_link(AdminFamiliesPage.edit_dob_ssn_text)
end

Then(/^Hbx Admin should see the edit form being rendered again with a validation error message$/) do
  sleep 2
  expect(page).to have_content(/Edit DOB \/ SSN/i)
  expect(page).to have_content(/must have 9 digits/i)
end

When(/^Hbx Admin enters a valid DOB and SSN and clicks on update$/) do
  fill_in 'person[ssn]', :with => '212-31-3131'
  page.find_button("Update").click
  page.driver.browser.switch_to.alert.accept
end

Then(/^Hbx Admin should see the update partial rendered with update sucessful message$/) do
  expect(page).to have_content(/DOB \/ SSN Update Successful/i)
end

When(/^Hbx Admin clicks Families tab$/) do
  visit exchanges_hbx_profiles_root_path
  find(AdminHomepage.families_dropown, :wait => 10).click
  find(AdminHomepage.families_btn, :wait => 10).click
end
