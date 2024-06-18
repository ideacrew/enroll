# frozen_string_literal: false

Given(/^that a person exists in EA$/) do
  visit "/"
  click_link 'Consumer/Family Portal'
  FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period)
  FactoryBot.create(:qualifying_life_event_kind, market_kind: "individual")
  FactoryBot.create(:qualifying_life_event_kind, :effective_on_event_date_and_first_month, market_kind: "individual")
  BenefitMarkets::Products::ProductRateCache.initialize_rate_cache!
  # screenshot("individual_start")
  sleep 10
  fill_in CreateAccount.email_or_username, :with => "testflow@test.com"
  fill_in SignIn.password, :with => "aA1!aA1!aA1!"
  fill_in CreateAccount.password_confirmation, :with => "aA1!aA1!aA1!"
  # screenshot("create_account")
  click_button "Create Account"
  expect(page).to have_content("Your Information")
  expect(page).to have_content("CONTINUE")
  click_link "CONTINUE"
  sleep 5
end

Given(/^Hbx Admin creates a consumer application$/) do
  visit exchanges_hbx_profiles_root_path
  find('.interaction-click-control-families', wait: 10).click
  page.find('.interaction-click-control-new-consumer-application', wait: 10).click
  visit begin_consumer_enrollment_exchanges_agents_path
  fill_in "person_first_name", with: "John"
  fill_in "person_last_name", with: "Smith"
  fill_in "jq_datepicker_ignore_person_dob", with: "11/11/1991"
  fill_in "person_ssn", with: '212-31-3131'
  find(:xpath, '//label[@for="radio_male"]', wait: 10).click
  find('.btn', text: 'CONTINUE', wait: 10).click
  expect(page).to have_content("Next, we need to verify if you or you and your family are eligible to enroll in coverage through #{site_short_name} Select CONTINUE.")
  find(IvlPersonalInformation.continue_btn, wait: 10).click
  find('span.label', text: 'choose *', wait: 10).click
  find("li", :text => "Paper").click
  find(:xpath, '//label[@for="person_us_citizen_true"]', wait: 10).click
  find(:xpath, '//label[@for="person_naturalized_citizen_false"]', wait: 10).click
  find(:xpath, '//label[@for="indian_tribe_member_no"]', wait: 10).click
  find(:xpath, '//label[@for="radio_incarcerated_no"]', wait: 10).click
  fill_in "person_addresses_attributes_0_address_1", with: "123 Main St NE"
  fill_in "person_addresses_attributes_0_address_2", with: "apt 1005"
  fill_in "person_addresses_attributes_0_city", with: "Washington"
  find(:xpath, "//span[@class='label'][contains(., 'SELECT STATE')]", wait: 10).click
  find(:xpath, '//*[@id="address_info"]/div/div[3]/div[2]/div/div[3]/div/ul/li[10]', wait: 10).click
  fill_in "person[addresses_attributes][0][zip]", with: "35465"
  find('.btn', text: 'CONTINUE', wait: 10).click
end

And(/^the person has an active consumer role$/) do
  fill_in "person_first_name", with: "John"
  fill_in "person_last_name", with: "Smith"
  fill_in "jq_datepicker_ignore_person_dob", with: "11/11/1991"
  fill_in "person_ssn", with: '212-31-3131'
  find(:xpath, '//label[@for="radio_male"]').click
  find(:xpath, '//label[@for="is_applying_coverage_true"]').click
  # screenshot("register")
  find('.btn', text: 'CONTINUE').click
  find('.interaction-click-control-continue', text: 'CONTINUE', :wait => 10).click
end

And(/the person fills in all personal info/) do
  expect(page).to have_content("Personal Information")
  expect(page).to have_content("CONTINUE")
  fill_in IvlPersonalInformation.first_name, with: "John"
  fill_in IvlPersonalInformation.last_name, with: "Smith"
  fill_in IvlPersonalInformation.dob, with: "11/11/1991"
  fill_in IvlPersonalInformation.ssn, with: '212-31-3131'
  find(IvlPersonalInformation.male_radiobtn).click
  find(IvlPersonalInformation.need_coverage_yes).click
  find(IvlPersonalInformation.continue_btn).click
  find(IvlPersonalInformation.continue_btn).click
  find(IvlPersonalInformation.us_citizen_or_national_yes_radiobtn).click
  find(IvlPersonalInformation.naturalized_citizen_no_radiobtn).click
  find(IvlPersonalInformation.american_or_alaskan_native_no_radiobtn).click
  find(IvlPersonalInformation.incarcerated_no_radiobtn).click
  find(IvlPersonalInformation.tobacco_user_no_radiobtn).click unless !tobacco_user_field_enabled?
  fill_in IvlPersonalInformation.address_line_one, with: "123 fake st"
  fill_in IvlPersonalInformation.city, with: "DC"
  find(IvlPersonalInformation.select_state_dropdown).click
  find(IvlPersonalInformation.select_dc_state).click
  fill_in IvlPersonalInformation.zip, with: '20002'
  find(IvlPersonalInformation.continue_btn).click
  sleep 20
end

And(/^the person has an active resident role$/) do
  fill_in "person_first_name", with: "John"
  fill_in "person_last_name", with: "Smith"
  fill_in "jq_datepicker_ignore_person_dob", with: "11/11/1991"
  find('.interaction-choice-control-value-person-no-ssn').click
  find(:xpath, '//label[@for="radio_male"]').click
  find(:xpath, '//label[@for="is_applying_coverage_true"]').click
  # screenshot("register")
  find('.btn', text: 'CONTINUE').click
  find('.interaction-click-control-continue', text: 'CONTINUE', :wait => 10).click
end

And(/^the person goes plan shopping in the individual for a new plan$/) do
  sleep 10
  wait_for_ajax
  find('.btn', text: 'CONTINUE').click
  click_link "Continue"
  sleep 5
  expect(page).to have_content('Verify Identity')
  find(:xpath, '//label[@for="interactive_verification_questions_attributes_0_response_id_a"]', wait: 5).click
  find(:xpath, '//label[@for="interactive_verification_questions_attributes_1_response_id_c"]', wait: 5).click
  # screenshot("identify_verification")
  click_button "Submit"
  # screenshot("override")
  click_link "Continue Application"
end

And(/the person continues to plan selection/) do
  find('.btn', text: 'CONTINUE').click
  sleep 4
  find('.btn', text: 'CONTINUE').click
  sleep 4
end

And(/the person selects a plan/) do
  find_all(IvlChoosePlan.select_plan_btn)[0].click
end

When(/^the person enrolls in a Kaiser plan$/) do
  # screenshot("line 161")
  find_all('.interaction-click-control-continue').first.click
  find(IvlSpecialEnrollmentPeriod.married_link).click
  expect(page).to have_content "Married"
  # screenshot("past_qle_date")
  fill_in IvlSpecialEnrollmentPeriod.qle_date, :with => (TimeKeeper.date_of_record - 5.days).strftime("%m/%d/%Y")
  within '#qle-date-chose' do
    find(IvlSpecialEnrollmentPeriod.continue_qle_btn).click
  end
  expect(page).to have_content "Based on the information you entered, you may be eligible to enroll now but there is limited time"
  # screenshot("valid_qle")
  find(IvlSpecialEnrollmentPeriod.effective_date_continue_btn).click
  expect(page).to have_content "Choose Coverage for your Household"
  find(IvlChooseCoverage.continue_btn).click
  # screenshot("plan_shopping")
  find_all(IvlChoosePlan.select_plan_btn)[0].click
end

And(/^I click on purchase confirm button for matched person$/) do
  sleep 4
  find(IvlConfirmYourPlanSelection.i_agree_checkbox).click
  fill_in IvlConfirmYourPlanSelection.first_name, with: "John"
  fill_in IvlConfirmYourPlanSelection.last_name, with: "Smith"
  # screenshot("purchase")
  find(IvlConfirmYourPlanSelection.confirm_btn).click
end

And(/^tries to purchase with a break in coverage$/) do
  find('.btn', text: 'CONTINUE').click
  person = Person.where(first_name: /John/i, last_name: /Smith/i).to_a.first
  enrollment = person.primary_family.hbx_enrollments.first
  enrollment.update_attributes(aasm_state: "coverage_terminated", terminated_on: (TimeKeeper.date_of_record - 5.day)) if enrollment
  sleep 3
  click_button "Shop for Plans"
  click_link "Shop Now"
  find('.btn', text: 'CONTINUE').click
  click_button "Shop for new plan"
  find_all('.plan-select')[1].click
end

Then(/^I should click on pay now button$/) do
  find(IvlEnrollmentSubmitted.pay_now_btn).click
end

Then(/I should see the (.*) pop up text/) do |issuer|
  case issuer
  when 'Kaiser Permanente'
    carrier_name = 'Kaiser Permanente'
  when 'Anthm'
    carrier_name = 'Anthem Blue Cross and Blue Shield'
  end
  expect(page).to have_content(l10n("plans.issuer.pay_now.redirection_message", site_short_name: EnrollRegistry[:enroll_app].setting(:short_name).item, carrier_name: carrier_name))
end

And(/the Kaiser user form should be active/) do
  person = Person.where(first_name: /John/i, last_name: /Smith/i).to_a.first
  enrollment = person.primary_family.hbx_enrollments.first
  expect(page).to have_selector("#sp-#{enrollment.hbx_id}", visible: false)
end

Then(/I should see the non-Kaiser pop up text/) do
  expect(page).to have_content(l10n("plans.issuer.pay_now.redirection_message", site_short_name: EnrollRegistry[:enroll_app].setting(:short_name).item, carrier_name: "CareFirst"))
end

Then(/the user closes the pop up modal/) do
  find(IvlEnrollmentSubmitted.go_back_btn).click
end

Then(/user continues to their account/) do
  find(IvlEnrollmentSubmitted.go_to_my_acct_btn).click
end

Then(/^I should see( not)? pay now button$/) do |visible|
  if visible.blank?
    expect(page).to have_css(IvlEnrollmentSubmitted.pay_now_btn)
  else
    expect(page).not_to have_css(IvlEnrollmentSubmitted.pay_now_btn)
  end
end

And(/^I should see model pop up$/) do
  expect(page).to have_css('.modal-open')
end

And(/^I should see Leave DC Health LINK buttton$/) do
  expect(page).to have_content('LEAVE DC HEALTH LINK')
end

And(/^I should be able to click  Leave DC Health LINK buttton$/) do
  find('.interaction-click-control-leave-dc-health-link').click
  sleep 5
end

Then(/^I should be able to view DC Health LINK text$/) do
  expect(page).to have_content("You are leaving the DC Health Link website and entering a privately-owned website created, operated and maintained by Kaiser Permanente.")
end

And(/^I should see an alert with error message$/) do
  expect(page.driver.browser.switch_to.alert.text).to have_content("We're sorry, but something went wrong. You can try again, or pay once you receive your invoice.")
end

And(/^creates a consumer with SEP$/) do
  visit exchanges_hbx_profiles_root_path
  find(AdminHomepage.families_dropown, wait: 10).click
  page.find(AdminHomepage.new_consumer_app_btn, wait: 10).click
  visit begin_consumer_enrollment_exchanges_agents_path
  fill_in IvlPersonalInformation.first_name, with: "John"
  fill_in IvlPersonalInformation.last_name, with: "Smith"
  fill_in IvlPersonalInformation.dob, with: "11/11/1991"
  fill_in IvlPersonalInformation.ssn, with: '212-31-3131'
  find(IvlPersonalInformation.male_radiobtn, wait: 5).click
  find(IvlPersonalInformation.continue_btn).click
  expect(page).to have_content("Next, we need to verify if you or you and your family are eligible to enroll in coverage through #{site_short_name}. Select CONTINUE.")
  find(IvlPersonalInformation.continue_btn_2, wait: 5).click
  find(IvlPersonalInformation.application_type_dropdown, wait: 5).click
  find("li", :text => "Paper").click
  find(IvlPersonalInformation.us_citizen_or_national_yes_radiobtn, wait: 5).click
  find(IvlPersonalInformation.naturalized_citizen_no_radiobtn, wait: 5).click
  find(IvlPersonalInformation.american_or_alaskan_native_no_radiobtn, wait: 5).click
  find(IvlPersonalInformation.incarcerated_no_radiobtn, wait: 5).click
  fill_in IvlPersonalInformation.address_line_one, with: "123 Main St"
  fill_in IvlPersonalInformation.address_line_two, with: "apt 1005"
  fill_in IvlPersonalInformation.city, with: "Washington"
  find(IvlPersonalInformation.select_state_dropdown, wait: 5).click
  find_all(:xpath, "//li[contains(., '#{EnrollRegistry[:enroll_app].setting(:state_abbreviation).item}')]").last.click
  fill_in "person[addresses_attributes][0][zip]", with: EnrollRegistry[:enroll_app].setting(:contact_center_zip_code).item
  find(IvlPersonalInformation.continue_btn, wait: 10).click
  visit '/insured/consumer_role/upload_ridp_document'
  visit '/insured/consumer_role/upload_ridp_document'
  doc_id = "urn:openhbx:terms:v1:file_storage:s3:bucket:'id-verification'{#sample-key}"
  file_path = File.dirname(__FILE__)
  allow_any_instance_of(Insured::RidpDocumentsController).to receive(:file_path).and_return(file_path)
  allow(Aws::S3Storage).to receive(:save).with(file_path, 'id-verification').and_return(doc_id)
  find(IvlVerifyIdentity.upload_application_docs_btn).click
  within IvlVerifyIdentity.upload_application_docs_btn do
    attach_file("file[]", "#{Rails.root}/lib/pdf_templates/blank.pdf", visible: false)
  end
  wait_for_ajax(2)
  expect(page).to have_content('File Saved')
  expect(page).to have_content('In Review')
  sleep 2
  within('#Application') do
    find(IvlVerifyIdentity.application_actions_dropdown).click
    find(IvlVerifyIdentity.application_verify_btn).click
  end
  find(IvlVerifyIdentity.select_reason_dropdown).click
  find('li', :text => 'Document in EnrollApp').click
  find('.v-type-confirm-button').click
  expect(page).to have_content('Application successfully verified.')
  find(IvlVerifyIdentity.continue_btn).click
  FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period)
  FactoryBot.create(:qualifying_life_event_kind, market_kind: "individual")
  FactoryBot.create(:qualifying_life_event_kind, :effective_on_event_date_and_first_month, market_kind: "individual")
end

And(/^the consumer with SEP is RIDP verified$/) do
  ::Person.all_consumer_roles.each { |per| per.consumer_role.move_identity_documents_to_verified }
end

Then(/^\w+ should the the First Payment button/) do
  expect(page).to have_content('Make a first payment')
end

Then(/user clicks on the first payment button/) do
  find(IvlHomepage.first_payment).click
end

Then(/^\w+ should the the Make Payments button/) do
  expect(page).to have_content('Make payments')
end

Then(/^\w+ should not see the Make Payments button/) do
  expect(page).not_to have_content('Make payments')
end

Then(/user clicks on the make payments button/) do
  find(IvlHomepage.make_payments_btn).click
end

Given(/non-Kaiser enrollments exist/) do
  BenefitSponsors::Organizations::GeneralOrganization.each do |org|
    org.update_attributes!(legal_name: "CareFirst")
  end
end

And(/the first payment glossary tooltip should be present/) do
  expect(find(IvlHomepage.first_payment_glossary)).to be_truthy
end

And(/the make payments glossary tooltip should be present/) do
  expect(find(IvlHomepage.make_payments_btn_glossary)).to be_truthy
end

And(/the person lands on home page/) do
  visit "families/home"
end

And(/^\w+ tries to purchase with a break in coverage$/) do
  person = Person.where(first_name: /John/i, last_name: /Smith/i).to_a.first
  enrollment = person.primary_family.hbx_enrollments.first
  enrollment&.update_attributes(aasm_state: "coverage_terminated", terminated_on: (TimeKeeper.date_of_record + 10.day))
  sleep 3
  visit 'families/home'
end

When(/^the consumer select a future qle date$/) do
  expect(page).to have_content "Had a baby"
  # screenshot("past_qle_date")
  fill_in IvlSpecialEnrollmentPeriod.qle_date, :with => (TimeKeeper.date_of_record).strftime("%m/%d/%Y")
  click_link(TimeKeeper.date_of_record.day)
  within '#qle-date-chose' do
    find(IvlSpecialEnrollmentPeriod.continue_qle_btn).click
  end
  find("[name='effective_on_kind'] option[value='date_of_event']").select_option
  find(IvlSpecialEnrollmentPeriod.effective_date_continue_btn).click
end

And(/^the person click on qle continue$/) do
  fill_in IvlSpecialEnrollmentPeriod.qle_date, :with => (TimeKeeper.date_of_record).strftime("%m/%d/%Y")
  within '#qle-date-chose' do
    find(IvlSpecialEnrollmentPeriod.continue_qle_btn).click
  end
  find(IvlSpecialEnrollmentPeriod.effective_date_continue_btn).click
end

Given(/^a (.*) site exists$/) do |site_key|
  skip_this_scenario unless EnrollRegistry[:enroll_app].setting(:state_abbreviation).item == site_key
end
