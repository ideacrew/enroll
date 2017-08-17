
Given(/^that the user is applying for a CONSUMER role$/) do
  visit "/users/sign_up"
  fill_in "user_oim_id", with: user_sign_up[:oim_id]
  fill_in "user_password", with: user_sign_up[:password]
  fill_in "user_password_confirmation", with: user_sign_up[:password_confirmation]
  click_button "Create account"
end

And(/the primary member has supplied mandatory information required$/) do
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
  expect(page).to have_content('Thank you. Next, we need to verify if you or you and your family are eligible to enroll in coverage through DC Health Link. Please select CONTINUE.')
  find('.btn', text: 'CONTINUE').click
  find(:xpath, '//label[@for="person_us_citizen_true"]').click
  find(:xpath, '//label[@for="person_naturalized_citizen_false"]').click
  find(:xpath, '//label[@for="indian_tribe_member_no"]').click
  find(:xpath, '//label[@for="radio_incarcerated_no"]').click
  find(:xpath, '//label[@for="radio_physically_disabled_no"]').click
  fill_in "person_addresses_attributes_0_address_1", with: personal_information[:address_1]
  fill_in "person_addresses_attributes_0_address_2", with: personal_information[:address_2]
  fill_in "person_addresses_attributes_0_city", with: personal_information[:city]
  find(:xpath, "//p[@class='label'][contains(., 'SELECT STATE')]").click
  find(:xpath, '//*[@id="address_info"]/div/div[3]/div[2]/div/div[3]/div/ul/li[10]').click
  fill_in "person[addresses_attributes][0][zip]", with: personal_information[:zip]
  find('.btn', text: 'CONTINUE').click
end

Given(/^the primary member authorizes the system to call EXPERIAN$/) do
  expect(page).to have_content('Authorization and Consent')
  find(:xpath, '//label[@for="agreement_agree"]').click
  find('.btn', text: 'CONTINUE').click
end

Given(/^system receives a positive response from EXPERIAN$/) do
  expect(page).to have_content('Verify Identity')
end

Given(/^the user answers all VERIFY IDENTITY  questions$/) do 
  expect(page).to have_content('Verify Identity')
  find(:xpath, '//label[@for="interactive_verification_questions_attributes_0_response_id_a"]').click
  find(:xpath, '//label[@for="interactive_verification_questions_attributes_1_response_id_c"]').click
end

When(/^the user clicks submit$/) do
  click_button "Submit"
end

When(/^Experian returns a VERIFIED response$/) do
  click_link "Please click here once you have contacted the exchange and have been told to proceed."
end

Then(/^The user will navigate to the Help Paying for Coverage page$/) do
  expect(page).to have_content('Help Paying for Coverage')
end

Given(/^the user is on the Help Paying For Coverage page$/) do
  expect(page).to have_content('Verify Identity')
  find(:xpath, '//label[@for="interactive_verification_questions_attributes_0_response_id_a"]').click
  find(:xpath, '//label[@for="interactive_verification_questions_attributes_1_response_id_c"]').click
  click_button "Submit"
  click_link "Please click here once you have contacted the exchange and have been told to proceed."
end

When(/^the user clicks CONTINUE$/) do
  expect(page).to have_content('Help Paying for Coverage')
  find('.btn', text: 'CONTINUE').click
end

When(/^the answer to Do you want to apply for Medicaid… is NIL$/) do
  # expect(find_field('radio1')).to be_checked
  # expect(find_field('radio2')).to be_checked
end

Then(/^the user will remain on the page$/) do
  expect(page).to have_content('Do you want to apply for Medicaid, tax credits, savings and cost-sharing reductions ? *')
end

Then(/^an error message will display stating the requirement to populate an answer$/) do
  expect(page).to have_content('Please choose an option before you proceed.')
end
