
When(/^the user clicks Change FEIN link in the Actions dropdown for that Employer$/) do
  find('.dropdown.pull-right', text: 'Actions').click
  click_link('Change FEIN')
end

And(/^an FEIN with less than nine digits is entered$/) do
  find('#organizations_general_organization_new_fein').set("89-423")
end

And(/^the user clicks submit button$/) do
  page.find_button('submit').trigger('click')
end

Then(/^an warning message will be presented as FEIN must be at least nine digits$/) do
  expect(page).to have_content('FEIN must be at least 9 digits')
end

And(/^an FEIN with nine digits matches an existing Employer Profile FEIN$/) do
  find('#organizations_general_organization_new_fein').set(second_employer[:fein])
end

Then(/^an warning message will be presented as FEIN matches HBX ID Legal Name$/) do
  expect(page).to have_content("FEIN matches HBX ID #{second_employer[:hbx_id]}, #{second_employer[:legal_name]}")
end

And(/^the user enters unique FEIN with nine digits$/) do
  find('#organizations_general_organization_new_fein').set("123456789")
end

Then(/^a success message will display at the top of the index$/) do
  expect(page).to have_content('FEIN Update Successful')
end
