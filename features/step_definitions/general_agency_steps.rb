# frozen_string_literal: true

Given(/general agency feature is enabled$/) do
  enable_feature :general_agency
end

Given(/general agency feature is disabled$/) do
  disable_feature :general_agency
end

When(/^.+ visit the HBX General Agency Registration form$/) do
  visit '/'
  find(".interaction-click-control-general-agency-registration", wait: 10).click
end

When(/^.+ visit the main portal$/) do
  visit '/'
end

When(/^the user types in the GA registration URL$/) do
  visit "/benefit_sponsors/profiles/registrations/new?profile_type=general_agency"
end

Then(/^user should not see General Agencies option for bulk notice$/) do
  expect(all_page_select_options.exclude?('general agency')).to eq(true)
end

Then(/^the user will not be able to access GA Registration page$/) do
  expect(page).to_not have_content("General Agency Registration")
  expect(page).to have_content(l10n("general_agency_not_enabled"))
end

Then(/^they should not see any General Agency link$/) do
  expect(all_page_links.exclude?('general agency registration')).to eq(true)
  expect(all_page_links.exclude?('general agency portal')).to eq(true)
  expect(page).to_not have_content("General Agencies")
end

Then(/^.+ should not see the New General Agency form/) do
  # Whats the point of this it will fail because of the General Agency Portal button on Welcome Page
  # expect(page).not_to have_content('General Agency')
end

Then(/^.+ should see the New General Agency form/) do
  expect(page).to have_content('General Agency / TPA Registration')
  expect(page).to have_css("#general_agency_form")
end

When(/General Agency enters personal information for agency$/) do
  fill_in 'organization[first_name]', with: 'Jack'
  fill_in 'organization[last_name]', with: 'Martin'
  fill_in 'jq_datepicker_ignore_organization[dob]', with: '10/01/1980'
  find('.interaction-field-control-person-email').click
  fill_in 'organization[email]', with: 'jack.martin@example.com'
  fill_in 'organization[npn]', with: '209209119'
end

And(/^.+ enters general agency information$/) do
  fill_in 'organization[legal_name]', with: "Housecare Inc"
  fill_in 'organization[dba]', with: "Housecare Inc"
  fill_in 'organization[fein]', with: "990880811"

  fill_in 'organization[home_page]', with: 'www.housecare.example.com'

  find(:xpath, "//p[@class='label'][contains(., 'Select Practice Area')]").click
  find(:xpath, "//li[contains(., 'Both – Individual & Family AND Small Business Marketplaces')]").click

  find(:xpath, "//label[input[@name='organization[accept_new_clients]']]").click
  find(:xpath, "//label[input[@name='organization[working_hours]']]").click
end

And(/^.+ clicks? on Create General Agency$/) do
  find('.interaction-click-control-create-general-agency').click
end

Then(/^.+ should see general agency registration successful message$/) do
  expect(page).to have_content('Your registration has been submitted. A response will be sent to the email address you provided once your application is reviewed.')
end

Then(/^.+ should see the list of general agencies$/) do
  expect(page).to have_content('General Agencies')
  expect(page).to have_content('Housecare Inc')
end

When(/^.+ clicks the link of Housecare Inc$/) do
  find(:xpath, "//a[contains(., 'Housecare Inc')]").click
end

Then(/^.+ should see the show page of general agency$/) do
  expect(page).to have_content('General Agency : Housecare Inc')
end

And(/^.+ clicks on the link of General agency$/) do
  find('.interaction-click-control-general-agencies').click
end

Then(/^.+ should see the list of general agency staff$/) do
  expect(page).to have_content('General Agency Staff')
  expect(page).to have_content('Housecare Inc')
  expect(page).to have_content('Jack Martin')
  expect(page).to have_content('Applicant')
end

When(/^Hbx Admin clicks on the Staff tab$/) do
  find('li#staffs-tab').click
end

When(/^.+ clicks the link of staff role$/) do
  find(:xpath, "//a[contains(., 'Jack Martin')]").click
end

Then(/^.+ should see the detail of staff$/) do
  expect(page).to have_content('Housecare Inc')
  expect(page).to have_content('Jack Martin')
  expect(page).to have_content('Applicant')
end

When(/^.+ clicks on approve staff button$/) do
  find(".interaction-click-control-general-agency-approve").click
end

Then(/^.+ should see the staff successful approved message$/) do
  expect(page).to have_content('Staff approved successfully.')
end

Then(/^.+ should receive an invitation email for staff$/) do
  open_email("jack.martin@example.com")
  expect(current_email.to).to eq(["jack.martin@example.com"])
end

When(/^.+ visits? invitation url in email for staff$/) do
  invitation_link = links_in_email(current_email).first
  invitation_link.sub!(/http\:\/\/127\.0\.0\.1\:3000/, '')
  visit(invitation_link)
end

When(/^.+ registers? with valid information for staff$/) do
  fill_in "user[oim_id]", with: "jack.martin@example.com"
  fill_in "user[password]", with: "aA1!aA1!aA1!"
  fill_in "user[password_confirmation]", with: "aA1!aA1!aA1!"
  click_button 'Create account'
end

Then(/^.+ should see successful message with general agency home page$/) do
  expect(page).to have_content("Welcome to #{EnrollRegistry[:enroll_app].setting(:short_name).item}. Your account has been created.")
  expect(page).to have_content('General Agency : Housecare Inc')
end

When(/^CareFirst Broker should see the New Broker Agency form$/) do
  expect(page).to have_css("#broker_agency_form")
end

When(/^.+ enters personal information for ga flow$/) do
  fill_in GeneralAgencyRegistration.first_name, with: 'Broker'
  fill_in GeneralAgencyRegistration.last_name, with: 'Martin'
  fill_in GeneralAgencyRegistration.dob, with: '05/07/1977'
  # find('.interaction-field-control-person-email').click
  fill_in GeneralAgencyRegistration.email, with: 'broker.martin@example.com'
  fill_in GeneralAgencyRegistration.npn, with: '761111111'
end

And(/^.+ enters broker agency information for ga flow$/) do
  fill_in GeneralAgencyRegistration.legal_name, with: "CareFirst Inc"
  fill_in GeneralAgencyRegistration.dba, with: "CareFirst Inc"
  # Auto-Generates FEIN
  # fill_in 'organization[fein]', with: "890222111"
  select "Both - Individual & Family AND Small Business Marketplaces", from: GeneralAgencyRegistration.practice_area_dropdown
  find(GeneralAgencyRegistration.accept_new_client_checkbox).click
  find(GeneralAgencyRegistration.evening_hours_checkbox).click
end

When(/^.+ registers with valid information for ga flow$/) do
  fill_in "user[oim_id]", with: "broker.martin@example.com"
  fill_in "user[password]", with: "aA1!aA1!aA1!"
  fill_in "user[password_confirmation]", with: "aA1!aA1!aA1!"
  create_account_input = page.all('input').detect { |input| input[:value] == 'Create Account' }
  create_account_input.click
end

Then(/^.+ should receive an invitation email for ga flow$/) do
  open_email("broker.martin@example.com", :with_subject => "Invitation to create your Broker account on #{EnrollRegistry[:enroll_app].setting(:short_name).item}")
  expect(current_email.to).to eq(["broker.martin@example.com"])
end

Then(/^.+ should see successful message with broker agency home page for ga flow$/) do
  expect(page).to have_content("Welcome to #{EnrollRegistry[:enroll_app].setting(:short_name).item}. Your account has been created.")
  expect(page).to have_content('Broker Agency : CareFirst Inc')
end

Then(/^.+ should see broker agency of CareFirst$/) do
  expect(page).to have_content('CareFirst Inc')
end

Then(/^CareFirst Broker should see the page of Broker Agency$/) do
  expect(page).to have_content('Broker Agency : CareFirst Inc')
end

Then(/^.+ should see list of employers and assign portal$/) do
  expect(page).to have_content('Employers')
  expect(page).to have_content('Acmega LLC')
  expect(page).to have_content('General Agencies')
  expect(page).to have_css("#general_agency_id")
end

When(/^.+ assign employer to general agency$/) do
  find("input[id^='broker_dt_employer_ids_']").click
  find(:xpath, "//p[@class='label'][contains(., 'Select General Agency')]").click
  find(:xpath, "//li[contains(., 'Housecare Inc')]").click
  find("#assign_general_agency").click

end

Then(/^.+ should see assign successful message$/) do
  expect(page).to have_content('Succesfully Assigned General Agency')
end

Then(/^.+ should see the assigned general agency$/) do
  expect(page).to have_content('Employers')
  expect(page).to have_content('Acmega LLC')
  expect(page).to have_content('General Agencies')
  expect(page).to have_content('Housecare Inc')
end

When(/^General Agency staff logs on the General Agency Portal$/) do
  visit "/"
  find("a.interaction-click-control-general-agency-portal").click
  find('.interaction-click-control-sign-in-existing-account').click

  fill_in "user[login]", with: "jack.martin@example.com"
  find('#user_login').set("jack.martin@example.com")
  fill_in "user[password]", with: "aA1!aA1!aA1!"
  fill_in "user[login]", :with => "jack.martin@example.com" unless find(:xpath, '//*[@id="user_login"]').value == "jack.martin@example.com"
  find('.interaction-click-control-sign-in').click
end

Then(/^.+ should see general agency home page$/) do
  expect(page).to have_content('General Agency : Housecare Inc')
end

Then(/^General Agency should see the list of employer$/) do
  expect(page).to have_content('Employers')
  expect(page).to have_content('Acmega LLC')
end

When(/^General Agency clicks on the link of employers$/) do
  find('.interaction-click-control-employers').click
end

When(/^Primary broker selects (.*?) from dropdown$/) do |general_agency_name|
  find(BrokerEmployersPage.select_general_agency_dropdown).click
  expect(page).to have_content(general_agency_name)
  find("option", text: general_agency_name).click
  find(BrokerEmployersPage.submit_btn).click
end
