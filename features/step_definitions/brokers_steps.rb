# frozen_string_literal: true

module BrokerStepsHelper
  include Config::AcaHelper
end

World(BrokerStepsHelper)

When(/^.+ visits the HBX Broker Registration form$/) do
  visit '/'
  find(".broker-registration", wait: 10).click
end

When(/^Primary Broker should see the New Broker Agency form$/) do
  find('#broker_registration_form', wait: 10)
  expect(page).to have_css("#broker_registration_form")
  # Agency fields are part of the broker registration form
  expect(page).to have_content("Broker Agency Information")
end

When(/^.+ enters personal information$/) do
  visit "/broker_registration"
  fill_in 'agency[staff_roles_attributes][0][first_name]', with: 'Ricky'
  fill_in 'agency[staff_roles_attributes][0][last_name]', with: 'Martin'
  fill_in 'inputDOB', with: '10/10/1984'
  fill_in 'inputEmail', with: 'ricky.martin@example.com'
  fill_in 'agency[staff_roles_attributes][0][npn]', with: '109109109'
end


And(/^.+ enters broker agency information for individual markets$/) do
  fill_in 'organization[legal_name]', with: "Logistics Inc"
  fill_in 'organization[dba]', with: "Logistics Inc"
  # Auto-Generates FEIN
  # fill_in 'organization[fein]', with: "890890891"

  # this field was hidden 4/13/2016
  # find(:xpath, "//p[@class='label'][contains(., 'Select Entity Kind')]").click
  # find(:xpath, "//li[contains(., 'C Corporation')]").click

  find(:xpath, "//p[@class='label'][contains(., 'Select Practice Area')]").click
  find(:xpath, "//li[contains(., 'Both - Individual & Family AND Small Business Marketplaces')]").click

  find('button.multiselect').click
  find(:xpath, '//label[input[@value="bn"]]').click
  find(:xpath, '//label[input[@value="fr"]]').click

  find(:xpath, "//label[input[@name='organization[accept_new_clients]']]").click
  find(:xpath, "//label[input[@name='organization[working_hours]']]").click
end

And(/^Current broker agency is fake fein$/) do
  broker_agency.is_fake_fein = true
  broker_agency.save
end

And(/^.+ enters broker agency information for SHOP markets$/) do
  fill_in 'agency[organization][legal_name]', with: "Logistics Inc"
  fill_in 'agency[organization][dba]', with: "Logistics Inc"
  # fill_in 'agency[organization][fein]', with: "890890891"
  # Auto-Generates FEIN
  # fill_in 'organization[fein]', with: "890890891"

  # this field was hidden 4/13/2016
  # find(:xpath, "//p[@class='label'][contains(., 'Select Entity Kind')]").click
  # find(:xpath, "//li[contains(., 'C Corporation')]").click

  # find(:xpath, "//p[@class='label'][contains(., 'Select Practice Area')]").click
  # find(:xpath, "//li[contains(., 'Small Business Marketplace ONLY')]").click
  select 'Small Business Marketplace ONLY', from: "agency_organization_profile_attributes_market_kind"
  # Languages
  find("option[value='tr']").click
  find("#agency_organization_profile_attributes_accept_new_clients").click

  if aca_broker_routing_information
    fill_in 'agency_organization_profile_attributes_ach_routing_number', with: '123456789'
    fill_in 'agency_organization_profile_attributes_ach_routing_number_confirmation', with: '123456789'
    fill_in 'agency_organization_profile_attributes_ach_account_number', with: '9999999999999999'
  end
  # Using this as a seperate step was deleting the rest of the form
  role = "Primary Broker"
  location = 'default_office_location'
  location = eval(location) if location.class == String
  RatingArea.where(zip_code: "01001").first || FactoryBot.create(:rating_area, zip_code: "01001", county_name: "Hampden", rating_area: Settings.aca.rating_areas.first)
  fill_in 'agency[organization][profile_attributes][office_locations_attributes][0][address_attributes][address_1]', :with => location[:address1]
  fill_in 'agency[organization][profile_attributes][office_locations_attributes][0][address_attributes][address_2]', :with => location[:address2]
  fill_in 'agency[organization][profile_attributes][office_locations_attributes][0][address_attributes][city]', :with => location[:city]
  select "DC", from: "inputState"
  # agency[organization][profile_attributes][office_locations_attributes][0][address_attributes][state]
  # find(:xpath, "//div[contains(@class, 'selectric-scroll')]/ul/li[contains(text(), '#{location[:state]}')]").click

  fill_in 'agency[organization][profile_attributes][office_locations_attributes][0][address_attributes][zip]', :with => location[:zip]
  if role.include? 'Employer'
    wait_for_ajax
    select "#{location[:county]}", :from => "agency[organization][profile_attributes][office_locations_attributes][0][address_attributes][county]"
  end
  fill_in 'agency[organization][profile_attributes][office_locations_attributes][0][phone_attributes][area_code]', :with => location[:phone_area_code]
  fill_in 'agency[organization][profile_attributes][office_locations_attributes][0][phone_attributes][number]', :with => location[:phone_number]
  wait_for_ajax
  # Clicking the 'Create Broker Agency' button
  find("#broker-btn").click
end


And(/^.+ clicks? on Create Broker Agency$/) do
  wait_for_ajax
  page.find('h1', text: 'Broker Registration').click
  wait_for_ajax
  # Clicking the 'Create Broker Agency' button
  find("#broker-btn").click
end

Then(/^.+ should see broker registration successful message$/) do
  if Settings.site.key == :dc
    expect(page).to have_content('Complete the following requirements to become a DC Health Link Registered Broker')
  end
  expect(page).to have_content('Your registration has been submitted. A response will be sent to the email address you provided once your application is reviewed.')
end

And(/^.+ should see the list of broker applicants$/) do
end


Then(/^.+ click the current broker applicant show button$/) do
  find('.interaction-click-control-broker-show').click
end

And(/^.+ should see the broker application with carrier appointments$/) do
  if (Settings.aca.broker_carrier_appointments_enabled)
    find_all("[id^=person_broker_role_attributes_carrier_appointments_]").each do |checkbox|
      checkbox.should be_checked
    end
    expect(page).to have_content("Carrier appointments for broker are not necessary for participation in #{Settings.site.long_name}")
  end
end

And(/^.+ click approve broker button$/) do
  find('.interaction-click-control-broker-approve').click
end

Then(/^.+ should see the broker successfully approved message$/) do
  expect(page).to have_content('Broker applicant approved successfully.')
end

When(/^(.*?) go[es]+ to the brokers tab$/) do |legal_name|
  profile = @organization[legal_name].employer_profile
  visit  benefit_sponsors.profiles_employers_employer_profile_path(profile.id, :tab=>'brokers')
end

And(/^.+ should receive an invitation email$/) do
  subject = if Settings.site.key == :dc
              "Invitation to create your Broker account on #{Settings.site.short_name}"
            else
              "Important information for accessing your new broker account through the #{Settings.site.short_name}"
            end
  open_email(
    "ricky.martin@example.com",
    :with_subject => subject
  )
  expect(current_email.to).to eq(["ricky.martin@example.com"])
end

When(/^.+ visits? invitation url in email$/) do
  invitation_link = links_in_email(current_email).first
  invitation_link.sub!(/http\:\/\/127\.0\.0\.1\:3000/, '')
  visit(invitation_link)
end

Then(/^.+ should see the login page$/) do
  find('.interaction-click-control-sign-in')
end

Then(/^.+ should see the create account page$/) do
  find('.create-account-btn')
end

When(/^.+ clicks? on Create Account$/) do
  find('.create-account-btn').click
end

When(/^.+ registers? with valid information$/) do
  fill_in "user[oim_id]", with: "ricky.martin@example.com"
  fill_in "user[password]", with: "aA1!aA1!aA1!"
  fill_in "user[password_confirmation]", with: "aA1!aA1!aA1!"
  find('.create-account-btn').click
end

Then(/^.+ should see bank information$/) do
  expect(page).to have_content('Big Bank')
end

Then(/^.+ should see successful message with broker agency home page$/) do
 #expect(page).to have_content("Welcome to #{Settings.site.short_name}. Your account has been created.")
  expect(page).to have_content("Broker Agency : #{broker_agency_profile.legal_name}")
end

Then(/^.+ should see no active broker$/) do
  expect(page).to have_content('You have no active Broker')
end

When(/^.+ clicks? on Browse Brokers button$/) do
  find('.interaction-click-control-browse-brokers').click
end

Then(/^.+ should see broker agencies index view$/) do
  @broker_agency_profiles.keys.each do |broker_agency_name|
    element = find("div#broker_agencies_listing a", text: /#{broker_agency_name}/i, wait: 5)
    expect(element).to be_present
  end
end

When(/^.+ searches broker agency (.*?)$/) do |legal_name|
  find('.broker_agencies_search')
  fill_in 'q', with: (legal_name || broker_agency_profile.legal_name)
  find('.search-wp .btn').click
end

When(/^.+ searches primary broker (.*?)$/) do |broker_name|
  find('.broker_agencies_search')
  fill_in 'q', with: broker_name
  find('.search-wp .btn').click
end

Then(/^.+ should see broker agency (.*?)$/) do |legal_name|
  element = find("div#broker_agencies_listing a", text: /#{legal_name || broker_agency_profile.legal_name}/i, wait: 5)
  expect(element).to be_present
end

Then(/^.+ clicks? select broker button$/) do
  click_link 'Select Broker'
end

Then(/^.+ should see confirm modal dialog box$/) do
  expect(page).to have_content('Broker Selection Confirmation')
end

Then(/^.+ confirms? broker selection$/) do
  within '.modal-dialog' do
    find('input.btn-primary').click
  end
end

Then(/^.+ should see broker selected successful message$/) do
  wait_for_ajax(1,0.5)
  expect(page).to have_content("Your broker has been notified of your selection and should contact you shortly. You can always call or email them directly. If this is not the broker you want to use, select 'Change Broker'.")
end

And(/^.+ should see broker (.*?) and agency (.*?) active for the employer$/) do |broker_name, agency_name|
  find('#active_broker_tab #employer-broker-card', text: /Active Broker/i, wait: 5)
  expect(page).to have_content(/#{broker_name}/i)
  expect(page).to have_content(/#{agency_name}/i)
end

When(/^.+ terminates broker$/) do
  find('.interaction-click-control-change-broker').click
  find('.modal-title', text: 'Broker Termination Confirmation', wait: 5)
  within '.modal-dialog' do
    click_link 'Terminate Broker'
  end
end

Then(/^.+ should see broker terminated message$/) do
  expect(page).to have_content('Broker terminated successfully.')
end

Then(/^.+ should see Employer (.*?) and click on legal name$/) do |legal_name|
  click_link legal_name
end

Then(/^.+ should see the Employer (.*?) page as Broker$/) do |legal_name|
  find('#home h4', text: legal_name, wait: 5)
  expect(page).to have_content("I'm a Broker")
end

When(/^Primary Broker publishes the benefit application$/) do
  find('.interaction-click-control-publish-plan-year').click
end

Then(/^.* creates and publishes a plan year$/) do
  find('.interaction-click-control-benefits').click
  find('.interaction-click-control-add-plan-year').click

  find(:xpath, '//p[@class="label"][contains(., "SELECT START ON")]').click
  find(:xpath, '//div[div/p[contains(., "SELECT START ON")]]//li[@data-index="1"]').click

  fill_in 'plan_year[fte_count]', with: '3'
  find('.interaction-click-control-continue').click

  fill_in "plan_year[benefit_groups_attributes][0][title]", with: "Silver PPO Group"

  find(:xpath, '//li/label[@for="plan_year_benefit_groups_attributes_0_plan_option_kind_single_carrier"]').click
  wait_for_ajax(10)
  find('.carriers-tab a').click
  wait_for_ajax(10,2)
  find('.reference-plan label').click
  wait_for_ajax(10)
  fill_in "plan_year[benefit_groups_attributes][0][relationship_benefits_attributes][0][premium_pct]", with: 50
  fill_in "plan_year[benefit_groups_attributes][0][relationship_benefits_attributes][1][premium_pct]", with: 50
  fill_in "plan_year[benefit_groups_attributes][0][relationship_benefits_attributes][2][premium_pct]", with: 50
  fill_in "plan_year[benefit_groups_attributes][0][relationship_benefits_attributes][3][premium_pct]", with: 50

  find('.interaction-click-control-create-plan-year').click
  find('.alert-notice')

  if (Settings.aca.enforce_employer_attestation.to_s == "true")
    find('.interaction-click-control-documents').click
    wait_for_ajax
    find('.interaction-click-control-upload').click
    wait_for_ajax
    find('#subject_Employee_Attestation').click
    # There is no way to actually trigger the click and upload functionality
    # with a JS driver.
    # So we commit 2 sins:
    #   1) We make the file input visible so we can set it.
    #   2) We make the submit button visible so we can click it.
    execute_script(<<-JSCODE)
     $('#modal-wrapper div.employee-upload input[type=file]').attr("style", "display: block;");
    JSCODE
    wait_for_ajax
    attach_file("file", "#{Rails.root}/test/JavaScript.pdf")
    execute_script(<<-JSCODE)
     $('#modal-wrapper div.employee-upload input[type=submit]').css({"visibility": "visible", "display": "inline-block"});
    JSCODE
    find("input[type=submit][value=Upload]").click
    wait_for_ajax
  end

  find('.interaction-click-control-benefits').click
  find('.interaction-click-control-publish-plan-year').click
  wait_for_ajax
end

Then(/^.+ sees employer census family created$/) do
  expect(page).to have_content('successfully created')
end

# Then(/^(?:Employee){0}+ should see the matched employee record form$/) do
#   screenshot("broker_employer_search_results")
#   expect(page).to have_content('Legal LLC')
# end

Then(/^.+ should see (.*?) as family and click on name$/) do |name|
  find(:xpath, "//li[contains(., 'Families')]/a").click
  expect(page).to have_content(name)
  click_link name
end

Then(/^.+ goes to the Consumer page$/) do
  expect(page).to have_content("My #{Settings.site.short_name}")
end

Then(/^Primary Broker should see (.*?) account$/) do |name|
  find('.family_members h1', text: 'Household Info: Family Members', wait: 5)
  find('.family_members span', text: name, wait: 5)
end

# Then(/^.+ is on the consumer home page$/) do
#   @browser.a(class: 'interaction-click-control-shop-for-plans').wait_until_present
# end

Then(/^.+ shops for plans$/) do
  @browser.a(class: 'interaction-click-control-shop-for-plans').click
end

Then(/^.+ sees covered family members$/) do
  wait_and_confirm_text(/Choose Benefits: Covered Family Members/)
  @browser.element(id: 'btn-continue').click
end

Then(/^.+ choses a healthcare plan$/) do
  wait_and_confirm_text(/Choose Plan/i)
  wait_and_confirm_text(/Apply/)
  plan = @browser.a(class: 'interaction-click-control-select-plan')
  plan.click
end

Then(/^.+ continues to the consumer home page$/) do
  wait_and_confirm_text(/Continue/)
  @browser.a(text: /Continue/).click
end

Given(/^zip code for county exists as rate reference$/) do
  FactoryBot.create(:rating_area, zip_code: '01010', county_name: 'Worcester', rating_area: Settings.aca.rating_areas.first,
    zip_code_in_multiple_counties: true)
end

Given(/^a valid ach record exists$/) do
  FactoryBot.create(:ach_record, routing_number: '123456789', bank_name: 'Big Bank')
end

#
Given(/^enters the existing zip code$/) do
  fill_in 'organization[office_locations_attributes][0][address_attributes][zip]', with: '01010'
end

Then(/^the county should be autopopulated appropriately$/) do
  wait_for_ajax
  select 'Test County', :from => "organization[office_locations_attributes][0][address_attributes][county]"
  expect(page).to have_select("organization[office_locations_attributes][0][address_attributes][county]", :selected => 'Test County')
end

Given(/^enters a non existing zip code$/) do
  fill_in 'organization[office_locations_attributes][0][address_attributes][zip]', with: '11011'
end

Then(/^the county should not be autopopulated appropriately$/) do
  wait_for_ajax
  expect(page).not_to have_select("organization[office_locations_attributes][0][address_attributes][county]", :options => ['Test County'])
end

Then(/broker (.*?) should receive application (.*?) notification$/) do |broker_name, notification_kind|
  broker_email_address = @brokers[broker_name]&.email_address
  subject =
    case notification_kind
    when 'denial'
      'Broker application denied'
    when 'approval'
      "Invitation to create your Broker account on #{site_short_name}"
    when 'pending'
      'Action Needed - Complete Broker Training for DC Health Link for Business'
    end
  open_email(
    broker_email_address,
    :with_subject => subject
  )
  expect(current_email.to).to eq([broker_email_address])
end

Then(/^.+ should see broker (.*?) under pending tab$/) do |broker_name|
  expect(page).to have_content(broker_name)
end

When(/^.+ click deny broker button$/) do
  find('.interaction-click-control-broker-deny').click
end

When(/^.+ click extend broker button$/) do
  find('.interaction-click-control-broker-extend').click
end

Then(/^.+ should see the broker application denied message$/) do
  expect(page).to have_content('Broker applicant denied.')
end

Then(/^.+ should see the broker application extended message$/) do
  expect(page).to have_content('Broker applicant is now extended.')
end