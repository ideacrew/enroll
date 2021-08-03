# frozen_string_literal: true

Given(/^the user is applying for a CONSUMER role$/) do
  hbx_profile = FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period)
  hbx_profile.benefit_sponsorship.benefit_coverage_periods.each do |bcp|
    ivl_product = FactoryBot.create(:benefit_markets_products_health_products_health_product, :ivl_product, application_period: (bcp.start_on..bcp.end_on))
    bcp.update_attributes!(slcsp_id: ivl_product.id)
  end

  visit "/users/sign_up"
  fill_in "user_oim_id", with: user_sign_up[:oim_id]
  fill_in "user_password", with: user_sign_up[:password]
  fill_in "user_password_confirmation", with: user_sign_up[:password_confirmation]
  click_button "Create Account"
  create_plan
end

And(/the primary member has filled mandatory information required$/) do
  visit privacy_insured_consumer_role_index_path
  expect(page).to have_content("Your Information")
  expect(page).to have_content("CONTINUE")
  click_link "CONTINUE"
  fill_in "person_first_name", with: personal_information[:first_name]
  fill_in "person_last_name", with: personal_information[:last_name]
  fill_in "jq_datepicker_ignore_person_dob", with: personal_information[:dob].to_s
  fill_in "person_ssn", with: personal_information[:ssn]
  find(:xpath, '//label[@for="radio_male"]').click
  find(:xpath, '//label[@for="is_applying_coverage_true"]').click
  find('.btn', text: 'CONTINUE').click
  expect(page).to have_content("Next, we need to verify if you or you and your family are eligible to enroll in coverage through #{Settings.site.short_name}. Select CONTINUE.")
  find('.btn', text: 'CONTINUE').click
  click_and_wait_on_stylized_radio('//label[@for="person_us_citizen_true"]', "person_us_citizen_true", "person[us_citizen]", "true")
  click_and_wait_on_stylized_radio('//label[@for="person_naturalized_citizen_false"]', "person_naturalized_citizen_false", "person[naturalized_citizen]", "false")
  click_and_wait_on_stylized_radio('//label[@for="indian_tribe_member_no"]', "indian_tribe_member_no", "person[indian_tribe_member]", "false")
  click_and_wait_on_stylized_radio('//label[@for="radio_incarcerated_no"]', "radio_incarcerated_no", "person[is_incarcerated]", "false")
  fill_in "person_addresses_attributes_0_address_1", with: personal_information[:address_1]
  fill_in "person_addresses_attributes_0_address_2", with: personal_information[:address_2]
  fill_in "person_addresses_attributes_0_city", with: personal_information[:city]
  find(:xpath, '//*[@id="address_info"]/div/div[3]/div[2]/div/div[2]/span').click
  find('#address_info li', :text => 'DC', wait: 5).click
  fill_in "person[addresses_attributes][0][zip]", with: personal_information[:zip]

  sleep 5
  find('.btn', text: 'CONTINUE').click
end

Given(/^the primary member authorizes system to call EXPERIAN$/) do
  expect(page).to have_content('Authorization and Consent')
  find(:xpath, '//label[@for="agreement_agree"]').click
  find('.btn', text: 'CONTINUE').click
end

Given(/^system receives a positive response from the EXPERIAN$/) do
  expect(page).to have_content('Verify Identity')
end

Given(/^the user answers all the VERIFY IDENTITY  questions$/) do
  expect(page).to have_content('Verify Identity')
  find(:xpath, '//label[@for="interactive_verification_questions_attributes_0_response_id_a"]').click
  find(:xpath, '//label[@for="interactive_verification_questions_attributes_1_response_id_c"]').click
end

When(/^the user clicks on submit button$/) do
  click_button "Submit"
end

When(/^the Experian returns a VERIFIED response$/) do
  click_link "Continue Application"
end

Then(/^the user will navigate to the Help Paying for Coverage page$/) do
  expect(page).to have_content('Your Application for Premium Reductions')
end

Given(/^the user navigates to the "Household Info" page with "no" selected$/) do
  find(:xpath, '//label[@for="radio2"]').click
  create_plan
  find('.btn', text: 'CONTINUE').click
  expect(page).to have_content("#{l10n('family_information')}")
end

When(/the user clicks on add member button/) do
  find(:xpath, '//*[@id="dependent_buttons"]/div/a').click
end

And(/^the user fills the the add member form/) do
  expect(page).to have_content(/lives with primary subscriber/i)
  fill_in "dependent[first_name]", :with => "John"
  fill_in "dependent[last_name]", :with => "Doe"
  fill_in "dependent[ssn]", :with => "763434355"
  fill_in "jq_datepicker_ignore_dependent[dob]", :with => "04/15/1988"
  click_link('15')

  find('.house .selectric span.label').click
  find(".house .selectric-items li", text: 'Spouse').click

  find(:xpath, '//label[@for="radio_female"]').click
  find(:xpath, '//label[@for="dependent_us_citizen_true"]').click
  find(:xpath, '//label[@for="dependent_naturalized_citizen_false"]').click
  find(:xpath, '//label[@for="indian_tribe_member_no"]').click
  find(:xpath, '//label[@for="radio_incarcerated_no"]').click
  # screenshot("add_member")
  all(:css, ".mz").last.click
  expect(page).to have_content("#{l10n('family_information')}")
end

And(/^the user fills the the applicant add member form with indian member yes/) do
  expect(page).to have_content('Lives with primary subscriber')
  fill_in "applicant[first_name]", :with => "John"
  fill_in "applicant[last_name]", :with => "Doe"
  fill_in "applicant[ssn]", :with => "763434355"
  fill_in "jq_datepicker_ignore_applicant[dob]", :with => "04/15/1988"
  click_link('15')

  find('.house .selectric span.label').click
  find(".house .selectric-items li", text: 'Spouse').click

  find(:xpath, '//label[@for="radio_female"]').click
  find(:xpath, '//label[@for="applicant_us_citizen_true"]').click
  find(:xpath, '//label[@for="applicant_naturalized_citizen_false"]').click
  find(:xpath, '//label[@for="indian_tribe_member_yes"]').click
  find(:xpath, '//label[@for="radio_incarcerated_no"]').click
end

And(/^the user fills the the aplicant add member form with indian member no/) do
  sleep 5

  expect(page).to have_content('Lives with primary subscriber')
  fill_in "applicant[first_name]", :with => "John"
  fill_in "applicant[last_name]", :with => "Doe"
  fill_in "applicant[ssn]", :with => "763434355"
  fill_in "jq_datepicker_ignore_applicant[dob]", :with => "04/15/1988"
  click_link('15')

  find('.house .selectric span.label').click
  find(".house .selectric-items li", text: 'Spouse').click

  find(:xpath, '//label[@for="radio_female"]').click
  find(:xpath, '//label[@for="applicant_us_citizen_true"]').click
  find(:xpath, '//label[@for="applicant_naturalized_citizen_false"]').click
  find(:xpath, '//label[@for="indian_tribe_member_no"]').click
  find(:xpath, '//label[@for="radio_incarcerated_no"]').click

  all(:css, ".mz").last.click
  sleep 3
end

Then(/user should still see the member of a tribe question/) do
  expect(page).to have_content('Is this person a member of an')
  expect(page).to_not have_content('Are you a US Citizen or US National?')
end

And(/the user clicks submit applicant form/) do
  all(:css, ".mz").last.click
end

Then(/the user should see an error message for indian tribal state and name/) do
  expect(page).to have_content("Tribal state is required")
  expect(page).to have_content("Tribal name is required")
end

And(/the user enters a tribal name with a number/) do
  fill_in "applicant[tribal_name]", :with => "abc1"
end

Then(/the user should see an error for tribal name containing a number/) do
  expect(page).to have_content("cannot contain numbers")
end

Given(/AI AN Details feature is enabled/) do
  enable_feature :indian_alaskan_tribe_details
end

Given(/No coverage tribe details feature is enabled/) do
  enable_fa_feature :no_coverage_tribe_details
end

Then(/the user should see the AI AN Details fields/) do
  expect(page).to have_content("Where is this person's tribe located?")
end

And(/^the user clicks the PREVIOUS link1/) do
  find('.interaction-click-control-previous').click
end

Then(/^the user navigates to Help Paying for Coverage page/) do
  expect(page).to have_content('Your Application for Premium Reductions')
end

Given(/^the user navigates to the "Household Info" page with "yes" selected/) do
  find(:xpath, '//label[@for="radio1"]').click
  create_plan
  find('.btn', text: 'CONTINUE').click
end

And(/^the .+ is navigated to Application checklist page/) do
  expect(page).to have_content('Application Checklist')
end

And(/^the .+ should see a modal popup/) do
  expect(page).to have_content(l10n('faa.cost_savings.start_new_application').to_s)
end

And(/^the .+ clicks on 'Start New Application' on modal popup/) do
  click_button 'Start new application'
end

When(/^the user clicks on CONTINUE button/) do
  find('.btn', text: 'CONTINUE').click
end

Then(/^the user will navigate to FAA Household Info: Family Members page/) do
  expect(page).to have_content("#{l10n('family_information')}")
end
