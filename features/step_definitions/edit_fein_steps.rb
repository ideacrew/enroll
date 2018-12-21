And(/^the user will see (.*?) | (.*?) window$/) do |text, window|
  if text == "submit"
    page.find_button('submit')
  elsif text == "editable"
    expect(page).to have_content('Change FEIN')
    org_fein = initial_application.benefit_sponsorship.organization.fein
    expect(page).to have_content(org_fein)
  else
    expect(page).to have_content(text)
  end
end

And(/^the user clicks Change FEIN$/) do
  click_link('Change FEIN')
end

And(/^the Change FEIN window will expand$/) do
  page.has_xpath?("//*[@id='change_fein']")
end

When(/^the user clicks Cancel X button$/) do
  find('.btn', text: 'Cancel').trigger('click')
end

Then(/^the Change FEIN window will collapse$/) do
  page.has_xpath?("//*[@id='change_fein']").blank?
end

And(/^an FEIN with less than nine digits is entered$/) do
  find('#organizations_general_organization_new_fein').set("4657")
end

When(/^the user clicks submit button$/) do
  page.find_button('submit').trigger('click')
end

Then(/^an warning message will be presented as FEIN must be at least nine digits$/) do
  expect(page).to have_content('FEIN must be at least 9 digits')
end

Given(/^an FEIN with nine digits matches an existing Employer Profile FEIN$/) do
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
