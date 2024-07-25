# frozen_string_literal: true

class VlpDocument
  VLP_DOCUMENT_KINDS = ["I-327 (Reentry Permit)", "I-551 (Permanent Resident Card)", "I-571 (Refugee Travel Document)", "I-766 (Employment Authorization Card)",
                        "Certificate of Citizenship","Naturalization Certificate","Machine Readable Immigrant Visa (with Temporary I-551 Language)", "Temporary I-551 Stamp (on passport or I-94)", "I-94 (Arrival/Departure Record)",
                        "I-94 (Arrival/Departure Record) in Unexpired Foreign Passport", "Unexpired Foreign Passport",
                        "I-20 (Certificate of Eligibility for Nonimmigrant (F-1) Student Status)", "DS2019 (Certificate of Eligibility for Exchange Visitor (J-1) Status)",
                        "Other (With Alien Number)", "Other (With I-94 Number)"].freeze
end

When(/^.+ visits the Consumer portal during open enrollment$/) do
  visit "/"
  find(HomePage.consumer_family_portal_btn).click
  FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period)
  FactoryBot.create(:qualifying_life_event_kind, market_kind: "individual")
  FactoryBot.create(:qualifying_life_event_kind, :effective_on_event_date_and_first_month, market_kind: "individual")
  BenefitMarkets::Products::ProductRateCache.initialize_rate_cache!
  # screenshot("individual_start")
  r_id = BenefitMarkets::Products::Product.all.where(title:  "IVL Test Plan Bronze")[1].id.to_s
  BenefitMarkets::Products::Product.all.where(title:  "IVL Test Plan Bronze")[0].update_attributes!(renewal_product_id: r_id)
end

Then(/^\w+ should see Go To Plan Compare button$/) do
  expect(page).to have_content(l10n("go_to_plan_compare"))
  click_link(l10n("go_to_plan_compare"))
  expect(page).to have_content("CHECKBOOK")
end

Then(/^\w+ should see (.*) title content$/) do |coverage_kind|
  if coverage_kind == "health"
    expect(page).to have_content(l10n("insured.plan_shoppings.show.health_title.content"))
  else
    expect(page).to have_content(l10n("insured.plan_shoppings.show.dental_title.content"))
  end
end

When(/^\w+ visits? the Insured portal outside of open enrollment$/) do
  FactoryBot.create(:hbx_profile, :no_open_enrollment_coverage_period)
  FactoryBot.create(:qualifying_life_event_kind, market_kind: "individual")
  BenefitMarkets::Products::ProductRateCache.initialize_rate_cache!

  visit "/"
  click_link 'Consumer/Family Portal'
  # screenshot("individual_start")
end

And(/Individual asks how to make an email account$/) do

  @browser.button(class: /interaction-click-control-create-account/).wait_until_present
  @browser.a(text: /Don't have an email account?/).fire_event("onclick")
  @browser.element(class: /modal/).wait_until_present
  @browser.element(class: /interaction-click-control-×/).fire_event("onclick")
end

Then(/Individual creates HBX account$/) do
  fill_in CreateAccount.email_or_username, :with => (@u.email :email)
  fill_in CreateAccount.password, :with => "aA1!aA1!aA1!"
  fill_in CreateAccount.password_confirmation, :with => "aA1!aA1!aA1!"
  find(CreateAccount.create_account_btn).click
end
And(/^I can see the select effective date$/) do
  expect(page).to have_content "SELECT EFFECTIVE DATE"
end

Then(/^I can see the error message (.*?)$/) do |message|
  expect(page).to have_content(message)
end

And(/the user sees Your Information page$/) do
  expect(page).to have_content YourInformation.your_information_text
  find(YourInformation.continue_btn).click
end

When(/the user registers as an individual$/) do
  fill_in IvlPersonalInformation.first_name, :with => (@u.first_name :first_name)
  fill_in IvlPersonalInformation.last_name, :with => (@u.last_name :last_name)
  fill_in IvlPersonalInformation.dob, :with => (@u.adult_dob :adult_dob)
  fill_in IvlPersonalInformation.ssn, :with => "262-61-3061"
  find(IvlPersonalInformation.male_radiobtn).click
  screenshot("register")
  find(IvlPersonalInformation.continue_btn).click
end

When(/the individual clicks continue on the personal information page$/) do
  find(IvlPersonalInformation.continue_btn).click
end

When(/the user registers as an individual with invalid SSN$/) do
  fill_in IvlPersonalInformation.first_name, :with => (@u.first_name :first_name)
  fill_in IvlPersonalInformation.last_name, :with => (@u.last_name :last_name)
  fill_in IvlPersonalInformation.dob, :with => (@u.adult_dob :adult_dob)
  fill_in IvlPersonalInformation.ssn, :with => "999-00-1234"
  find(IvlPersonalInformation.male_radiobtn).click
  find(IvlPersonalInformation.continue_btn).click
end

Then(/^Individual sees the error message (.*)$/) do |error_message|
  page.should have_content(error_message)
end

Then(/^Individual should see the error message Invalid Social Security number$/) do
  #waiting for ajax request to complete before checking the error message
  wait_for_ajax
  expect(page.find("#person_ssn")[:oninvalid]).to eq "this.setCustomValidity('Invalid Social Security number.')"
end

Then(/^Individual should not see the error message (.*)$/) do |error_message|
  expect(page).not_to have_content(error_message)
end

When(/^validate SSN feature is (.*)$/) do |feature|
  allow(EnrollRegistry[:ssn_ui_validation].feature).to receive(:is_enabled).and_return(true)
  if feature == "enabled"
    stub_const('Forms::ConsumerCandidate::SSN_REGEX', /^(?!666|000|9\d{2})\d{3}[- ]{0,1}(?!00)\d{2}[- ]{0,1}(?!0{4})\d{4}$/)
  else
    stub_const('Forms::ConsumerCandidate::SSN_REGEX', /\A\d{9}\z/)
  end
end

And(/the user will have to accept alert pop up for missing field$/) do
  sleep 1
  page.driver.browser.switch_to.alert.accept
end


When(/^\w+ clicks? on the Continue button$/) do
  find(IvlPersonalInformation.continue_btn, :wait => 10).click
end

When(/^\w+ clicks? on continue$/) do
  find(IvlPersonalInformation.continue_btn).click
  screenshot("create_account")
end

Then(/^.+ should see heading labeled personal information/) do
  expect(page).to have_content("Personal Information")
  expect(page).to have_css("#gender-tooltip")
end

Then(/^.+ should see disabled ssn & dob fields/) do
  expect(page.find("#person_ssn")[:disabled]).to eq "true"
  expect(page.find("input[name='jq_datepicker_ignore_person[dob]'")[:disabled]).to eq "true"
end

Then(/Individual should click on Individual market for plan shopping/) do
  wait_for_ajax
  expect(page).to have_button("CONTINUE", visible: false)
  find('.btn', text: 'CONTINUE').click
end

Then(/Individual sees form to enter personal information with checked female gender$/) do
  expect(find("#radio_female", visible: false)).to be_checked
end

Then(/^.+ sees form to enter personal information$/) do
  find(IvlPersonalInformation.us_citizen_or_national_yes_radiobtn).click
  find(IvlPersonalInformation.naturalized_citizen_no_radiobtn).click
  find(IvlPersonalInformation.american_or_alaskan_native_no_radiobtn).click
  find(IvlPersonalInformation.incarcerated_no_radiobtn).click
  #find(IvlPersonalInformation.tobacco_user_yes_radiobtn).click if tobacco_user_field_enabled?
  fill_in IvlPersonalInformation.address_line_one, :with => "4900 USAA BLVD NE"
  fill_in IvlPersonalInformation.address_line_two, :with => "212"

  if EnrollRegistry[:bs4_consumer_flow].enabled?
    fill_in IvlPersonalInformation.city, with: 'Augusta'
    find(IvlPersonalInformation.select_me_state).click
    fill_in IvlPersonalInformation.zip, with: '04330'
    fill_in IvlPersonalInformation.mobile_phone, :with => "22075555555"
  else
    fill_in IvlPersonalInformation.city, with: personal_information[:city]
    find_all(IvlPersonalInformation.select_state_dropdown).first.click
    fill_in "person[addresses_attributes][0][zip]", with: personal_information[:zip]
    find_all(:xpath, "//li[contains(., '#{EnrollRegistry[:enroll_app].setting(:state_abbreviation).item}')]").last.click
    fill_in IvlPersonalInformation.zip, :with => EnrollRegistry[:enroll_app].setting(:contact_center_zip_code).item
  end
  fill_in IvlPersonalInformation.home_phone, :with => "22075555555"
  sleep 30
end

Then(/the continue button has data disabled attribute$/) do
  find('button.interaction-click-control-continue', visible: false)['data-disable-with']
  #expect(continue_button).to eql(l10n("please_wait")) inside a haml file data diasbled with attribute
end

Then(/^.+ sees form to enter personal information but doesn't fill it out completely$/) do
  find(IvlPersonalInformation.us_citizen_or_national_yes_radiobtn).click
  find(IvlPersonalInformation.naturalized_citizen_no_radiobtn).click
  find(IvlPersonalInformation.american_or_alaskan_native_no_radiobtn).click
  find(IvlPersonalInformation.incarcerated_no_radiobtn).click
  find(IvlPersonalInformation.tobacco_user_yes_radiobtn).click if tobacco_user_field_enabled?
  fill_in IvlPersonalInformation.address_line_one, :with => "4900 USAA BLVD NE"
  fill_in IvlPersonalInformation.address_line_two, :with => "212"
  fill_in IvlPersonalInformation.city, :with => "Washington"
  find_all(IvlPersonalInformation.select_state_dropdown).first.click
  find_all(:xpath, "//li[contains(., '#{EnrollRegistry[:enroll_app].setting(:state_abbreviation).item}')]").last.click
  #fill_in IvlPersonalInformation.zip, :with => EnrollRegistry[:enroll_app].setting(:contact_center_zip_code).item
  fill_in IvlPersonalInformation.home_phone, :with => "22075555555"
  sleep 2
end

Then(/^.+ sees form to enter personal information but doesn't check every box$/) do
  find(IvlPersonalInformation.us_citizen_or_national_yes_radiobtn).click
  find(IvlPersonalInformation.naturalized_citizen_no_radiobtn).click
  # find(IvlPersonalInformation.american_or_alaskan_native_no_radiobtn).click
  find(IvlPersonalInformation.incarcerated_no_radiobtn).click
  find(IvlPersonalInformation.tobacco_user_yes_radiobtn).click if tobacco_user_field_enabled?
  fill_in IvlPersonalInformation.address_line_one, :with => "4900 USAA BLVD NE"
  fill_in IvlPersonalInformation.address_line_two, :with => "212"
  fill_in IvlPersonalInformation.city, :with => "Washington"
  find_all(IvlPersonalInformation.select_state_dropdown).first.click
  find_all(:xpath, "//li[contains(., '#{EnrollRegistry[:enroll_app].setting(:state_abbreviation).item}')]").last.click
  fill_in IvlPersonalInformation.zip, :with => EnrollRegistry[:enroll_app].setting(:contact_center_zip_code).item
  fill_in IvlPersonalInformation.home_phone, :with => "22075555555"
  sleep 2
end

And(/the individual enters address information$/) do
  fill_in IvlPersonalInformation.address_line_one, :with => "4900 USAA BLVD NE"
  fill_in IvlPersonalInformation.address_line_two, :with => "212"
  fill_in IvlPersonalInformation.city, :with => EnrollRegistry[:enroll_app].setting(:contact_center_city).item
  find_all(IvlPersonalInformation.select_state_dropdown).first.click
  find_all(:xpath, "//li[contains(., '#{EnrollRegistry[:enroll_app].setting(:state_abbreviation).item}')]").last.click
  fill_in IvlPersonalInformation.zip, :with => EnrollRegistry[:enroll_app].setting(:contact_center_zip_code).item
end

Then(/the individual enters a SEP$/) do
  find(IvlSpecialEnrollmentPeriod.had_a_baby_link).click
  fill_in IvlSpecialEnrollmentPeriod.qle_date, :with => "02/04/2021"
  find(IvlSpecialEnrollmentPeriod.continue_qle_btn).click
  select "02/04/2021", from: IvlSpecialEnrollmentPeriod.select_effective_date_dropdown
  find(IvlSpecialEnrollmentPeriod.effective_date_continue_btn).click
end

And(/^.+ selects (.*) for coverage$/) do |coverage|
  if coverage == "applying"
    find(:xpath, '//label[@for="is_applying_coverage_true"]').click
  else
    find(:xpath, '//label[@for="is_applying_coverage_false"]').click
  end
end

Then(/^the question "(.*)" is displayed$/) do |question|
  page_text = page.text.gsub("\n", ' ')
  expect(page_text).to include(question)
end

Then(/^the question "(.*)" is not displayed$/) do |question|
  expect(page).not_to have_content(question)
end

Then(/^tribal state dropdown box is clicked$/) do
  find_all(IvlPersonalInformation.tribe_state_dropdown).first.click
end

When(/^AI AN question is answered yes$/) do
  find_all(IvlPersonalInformation.american_or_alaskan_native_yes_radiobtn).first.click
end

Then(/^states dropdown should popup$/) do
  expect(page.find("#tribal-state-container .selectric-items").present?).to be_truthy
end

Then(/^.+ should see error message (.*)$/) do |text|
  page.should have_content(text)
end

Then(/^.+ should not see error message (.*)$/) do |text|
  page.should have_no_content(text)
end

Given(/^the strong password length feature is (.+)$/) do |feature|
  if feature == "enabled"
    allow(EnrollRegistry[:strong_password_length].feature).to receive(:is_enabled).and_return(true)
  else
    allow(EnrollRegistry[:strong_password_length].feature).to receive(:is_enabled).and_return(false)
  end
end

Then(/^Individual should see a minimum password length of (.+)$/) do |length|
  expect(page).to have_content("#{length} #{l10n('devise.registrations.characters_minimum')}")
end

Then(/^.+ should see the weak password error message$/) do
  page.should have_content(l10n("devise.errors.password_strength"))
end

And(/(.*) selects eligible immigration status$/) do |text|
  if text == "Dependent"
    find(:xpath, '//label[@for="dependent_us_citizen_false"]').click
    if EnrollRegistry[:immigration_status_checkbox].enabled?
      find('#dependent_eligible_immigration_status').click
    else
      find(:xpath, '//label[@for="dependent_eligible_immigration_status_true"]').click
    end
  else
    find(:xpath, '//label[@for="person_us_citizen_false"]').click
    if EnrollRegistry[:immigration_status_checkbox].enabled?
      peis_checkbox = find('#person_eligible_immigration_status')
      peis_checkbox.checked? ? peis_checkbox.double_click : peis_checkbox.click
    else
      find('label[for=person_eligible_immigration_status_true]').click
      choose 'person_eligible_immigration_status_true', visible: false, allow_label_click: true
    end
  end
end

Then(/Individual should see the i94 text/) do
  expect(page).to have_content('When entering the I-94 Number, only include 9 numbers followed by a letter or a number in the 10th position and a number in the 11th position.')
  expect(page).to have_content('You must enter exactly 11 characters into the I-94 field.')
  expect(page).to have_content("The I-94 number is also called the admissions number. It is an 11 character sequence found printed on Arrival/Departure records (For I-94 or Form I-94A.) It can also be found on the form I-9.")
end

Then(/selects the i94 document and fills required details (.*)$/) do |correct_or_incorrect|
  step "user selects i94 document and fills required details #{correct_or_incorrect}"
  step 'should fill in valid sevis, passport expiration_date, tribe_member and incarcerated details'
end

Then(/selects i94 unexpired foreign passport document and fills required details (.*)$/) do |correct_or_incorrect|
  find('.label', :text => 'Select document type', wait: 10).click
  find('li', :text => "I-94 – Arrival/departure record in unexpired foreign passport", match: :prefer_exact, wait: 10).click
  fill_in 'I 94 Number', with: (correct_or_incorrect == 'correctly' ? '123456789a1' : '@23#5678901')
  fill_in 'Passport Number', with: 'A123456'
  fill_in 'Visa Number', with: 'V1234567'
  step 'should fill in valid sevis, passport expiration_date, tribe_member and incarcerated details'
end

Then(/selects Other With I-94 Number document and fills required details (.*)$/) do |correct_or_incorrect|
  find('.label', :text => 'Select document type', wait: 10).click
  find('li', :text => 'Other (with I-94 number)', match: :prefer_exact, wait: 10).click
  fill_in 'I 94 Number', with: (correct_or_incorrect == 'correctly' ? '123456789a1' : '@23#5678901')
  fill_in 'Passport Number', with: 'A123456'
  fill_in 'Document Description', with: 'Other With I94 Number'
  step 'should fill in valid sevis, passport expiration_date, tribe_member and incarcerated details'
end

And(/should fill in valid sevis, passport expiration_date, tribe_member and incarcerated details/) do
  fill_in 'SEVIS ID', with: '1234567891'
  fill_in 'Passport Expiration Date', with: TimeKeeper.date_of_record.to_s
  click_link((TimeKeeper.date_of_record + 10.days).day.to_s)
  find('label[for=indian_tribe_member_no]', wait: 20).click
  find('label[for=radio_incarcerated_no]', wait: 10).click
  choose 'radio_incarcerated_no', visible: false, allow_label_click: true
end

Then(/^Individual (.*) go to Authorization and Consent page$/) do |argument|
  if argument == 'does'
    expect(page).to have_content('Authorization and Consent')
  else
    expect(page).not_to have_content('Authorization and Consent')
  end
end

Then(/select I-551 doc and fill details/) do
  find('.label', :text => 'Select document type', wait: 10).click
  find('li', :text => 'I-551 – Permanent resident card', wait: 10).click
  fill_in 'Alien Number', with: '987654323'
  fill_in 'Card Number', with: 'aaa1231231231'
  fill_in 'I-551 Expiration Date', with: TimeKeeper.date_of_record.to_s
  click_link((TimeKeeper.date_of_record + 10.days).day)
end

Then(/click citizen yes/) do
  find(:xpath, '//label[@for="person_us_citizen_true"]').click
end

Then(/click citizen no/) do
  find(:xpath, '//label[@for="person_us_citizen_false"]').click
end

When(/click eligible immigration status yes/) do
  if EnrollRegistry[:immigration_status_checkbox].enabled?
    peis_checkbox = find('#person_eligible_immigration_status')
    peis_checkbox.checked? ? peis_checkbox.double_click : peis_checkbox.click
  else
    find('label[for=person_eligible_immigration_status_true]', wait: 20).click
    choose 'person_eligible_immigration_status_true', visible: false, allow_label_click: true
  end
end

Then(/should find I-551 doc type/) do
  find('.label', :text => 'I-551 – Permanent resident card', wait: 10)
end

And(/should find alien number/) do
  find('#person_consumer_role_vlp_documents_attributes_0_alien_number')
end

And(/Individual edits dependent/) do
  find(:xpath, './html/body/div[3]/div[2]/div/div/div[2]/div[4]/ul/li/div/div[2]/div[4]/div/div/a').click
  wait_for_ajax
end

And(/Individual clicks on confirm member/) do
  all(:css, ".mz").last.click
end

When(/Individual clicks on Save and Exit/) do
  find('li a', text: 'SAVE & EXIT').click
end

Then(/Individual resumes enrollment/) do
  visit '/'
  click_link('Consumer/Family Portal', wait: 10)
end

Then(/Individual sees previously saved address/) do
  expect(page).to have_field('ADDRESS LINE 1 *', with: '4900 USAA BLVD', wait: 10)
  find('.btn', text: 'CONTINUE').click
end

When(/^the individual clicks on Individual and Family link should be on privacy agreeement page/) do
  wait_for_ajax
  find('.interaction-click-control-individual-and-family').click
  expect(page).to have_content('Authorization and Consent')
end

Then(/^.+ agrees to the privacy agreeement/) do
  wait_for_ajax
  #expect(page).to have_content IvlAuthorizationAndConsent.authorization_and_consent_text
  find_all(IvlAuthorizationAndConsent.continue_btn)[0].click
end

When(/^Individual clicks on Individual and Family link/) do
  wait_for_ajax
  find(IvlFamilyInformation.individual_and_family_link).click
end

Then(/^Individual should be on verification page/) do
  expect(page).to have_content('Verify Identity')
end

When(/^.+ clicks on the Continue button of the Family Information page$/) do
  find_all(IvlIapFamilyInformation.continue_btn)[1].click unless EnrollRegistry[:bs4_consumer_flow].enabled?
  find(IvlIapFamilyInformation.continue_btn).click
  sleep 10
end

When(/^Individual navigates to Sep Page$/) do
  find_all(IvlIapFamilyInformation.continue_btn)[0].click
end

When(/^Individual clicks on the continue button$/) do
  wait_for_ajax
  find_all('.interaction-click-control-continue')[0].click
end

Then(/^.+ answers the questions of the Identity Verification page and clicks on submit/) do
  sleep 10
  expect(page).to have_content IvlVerifyIdentity.verify_identity_text
  find(IvlVerifyIdentity.pick_answer_a).click
  find(IvlVerifyIdentity.pick_answer_c).click
  screenshot("identify_verification")
  find(IvlVerifyIdentity.submit_btn).click
  screenshot("override")
  if EnrollRegistry[:bs4_consumer_flow].enabled?
    find_all(IvlVerifyIdentity.continue_application_btn)[1].click
  else
    sleep 2
    find(IvlVerifyIdentity.continue_application_btn).click
  end
end

Then(/^.+ is on the Help Paying for Coverage page/) do
  expect(page).to have_content IvlIapHelpPayingForCoverage.your_application_for_premium_reductions_text
  if EnrollRegistry[:mainecare_cubcare_glossary].enabled?
    expect(find('.weight-n.required')).to_not be(nil)
    expect(page).to have_css('.glossary', text: 'Cub Care')
    find('span[data-title="Cub Care"]').click
    expect(page).to have_content(IvlIapHelpPayingForCoverage.cubcare_glossary_text)
    find('div[class="mt-4 mb-4"]').click
  end
end

Then(/^.+ does not apply for assistance and clicks continue/) do
  find(IvlIapHelpPayingForCoverage.no_radiobtn).click
  find(IvlIapHelpPayingForCoverage.continue_btn).click
end

Then(/\w+ should see the dependents form/) do
  expect(page).to have_content('Add New Person')
  # screenshot("dependents")
end

And(/Individual clicks on add member button/) do
  find(:xpath, '//*[@id="dependent_buttons"]/div/a').click
  expect(page).to have_content('Lives with primary subscriber')

  fill_in "dependent[first_name]", :with => @u.first_name
  fill_in "dependent[last_name]", :with => @u.last_name
  fill_in "jq_datepicker_ignore_dependent[dob]", :with => @u.adult_dob
  click_link(@u.adult_dob.to_date.day)
  fill_in "dependent[ssn]", :with => @u.ssn
  find("span", :text => "choose").click
  find(:xpath, "//div[@class='selectric-scroll']/ul/li[contains(text(), 'Sibling')]").click
  find(:xpath, '//label[@for="radio_female"]').click
  find(:xpath, '//label[@for="dependent_us_citizen_true"]').click
  find(:xpath, '//label[@for="dependent_naturalized_citizen_false"]').click
  find(:xpath, '//label[@for="indian_tribe_member_no"]').click
  find(:xpath, '//label[@for="radio_incarcerated_no"]').click
  all(:css, ".mz").last.click
end

And(/Individual again clicks on add member button/) do
  find(:xpath, '//*[@id="dependent_buttons"]/div/a').click
  expect(page).to have_content('Lives with primary subscriber')

  fill_in "dependent[first_name]", :with => @u.first_name
  fill_in "dependent[last_name]", :with => @u.last_name
  fill_in "jq_datepicker_ignore_dependent[dob]", :with => '01/15/2013'
  click_link('15')
  fill_in 'dependent[ssn]', :with => @u.ssn
  find("span", :text => "choose").click
  find(:xpath, "//div[@class='selectric-scroll']/ul/li[contains(text(), 'Sibling')]").click
  find(:xpath, '//label[@for="radio_female"]').click
  find(:xpath, '//label[@for="dependent_us_citizen_true"]').click
  find(:xpath, '//label[@for="dependent_naturalized_citizen_false"]').click
  find(:xpath, '//label[@for="indian_tribe_member_no"]').click
  find(:xpath, '//label[@for="radio_incarcerated_no"]').click

  #testing
  # screenshot("added member")
  all(:css, ".mz").last.click
  sleep 2
end


And(/^.+ clicks on the Continue button of the Household Info page/) do
  screenshot("line 161")
  sleep 2
  find('.interaction-click-control-continue').click
end

Then(/consumer clicked on Go To My Account/) do
  click_link 'GO TO MY ACCOUNT'
end

Then(/Individual creates a new HBX account$/) do
  fill_in CreateAccount.email_or_username, :with => "testflow@test.com"
  fill_in CreateAccount.password, :with => "aA1!aA1!aA1!"
  fill_in CreateAccount.password_confirmation, :with => "aA1!aA1!aA1!"
  find(CreateAccount.create_account_btn, wait: 5).click
end

Then(/Individual creates a new HBX account with a weak password$/) do
  fill_in CreateAccount.email_or_username, :with => "testflow@test.com"
  fill_in CreateAccount.password, :with => "BadPw1!"
  fill_in CreateAccount.password_confirmation, :with => "BadPw1!"
  find(CreateAccount.create_account_btn).click
end

When(/I click on none of the situations listed above apply checkbox$/) do
  sleep 2
  expect(page).to have_content 'None of the situations listed above apply'
  find('#no_qle_checkbox').click
  expect(page).to have_content 'To enroll before open enrollment'
end

When(/Individual focus on the password field$/) do
  find('.interaction-field-control-user-password').click
end

When(/Individual enters the password$/) do
  fill_in CreateAccount.email_or_username, :with => "testflow@test.com"
  fill_in CreateAccount.password, :with => "BadPw1!"
end

Then(/Individual does not see the error on tooltip indicating a password longer than 20 characters$/) do
  unless EnrollRegistry[:bs4_consumer_flow].enabled?
    wait_for_ajax
    script = "return document.querySelector('.longer').getAttribute('data-icon');"
    data_icon_value = page.execute_script(script)
    expect(data_icon_value).to eq('check')
  end
end

Then(/^Individual should see the password tooltip with text minimum characters (.+)$/) do |length|
  expect(page).to have_content("Be at least #{length} characters")
end

And(/I click on back to my account button$/) do
  expect(page).to have_content "To enroll before open enrollment, you must qualify for a special enrollment period"
  find('.interaction-click-control-back-to-my-account').click
end

Then(/I should land on home page$/) do
  sleep 1
  expect(page).to have_content "My #{EnrollRegistry[:enroll_app].setting(:short_name).item}"
end

And(/I click on log out link$/) do
  find('.interaction-click-control-logout').click
end

And(/^.+ click on Sign In$/) do
  expect(page).to have_content EnrollRegistry[:enroll_app].setting(:header_message).item
end

And(/I signed in$/) do
  sleep 2
  find('.btn-link', :text => 'Sign In', wait: 5).click
  sleep 5
  fill_in SignIn.username, :with => "testflow@test.com"
  fill_in SignIn.password, :with => "aA1!aA1!aA1!"
  find(SignIn.sign_in_btn).click
end

When(/^the individual continues to the Choose Coverage page$/) do
  expect(page).to have_content IvlChooseCoverage.choose_coverage_for_your_household_text
end

When(/^the individual clicks the Continue button of the Group Selection page$/) do
  expect(page).to have_content IvlChooseCoverage.choose_coverage_for_your_household_text
  wait_for_ajax
  find(IvlChooseCoverage.continue_btn).click
end

Then(/I click on back to my account$/) do
  expect(page).to have_content "Choose Coverage for your Household"
  find('.interaction-click-control-back-to-my-account').click
end

And(/Aptc user signed in$/) do
  sleep 2
  find('.btn-link', :text => 'Sign In', wait: 5).click
  sleep 5
  fill_in SignIn.username, :with => "aptc@dclink.com"
  fill_in SignIn.password, :with => "aA1!aA1!aA1!"
  find(SignIn.sign_in_btn).click
end

And(/^.+click on continue button on group selection page$/) do
  click_button 'CONTINUE', :wait => 10
end

And(/.+ selects a plan on plan shopping page/) do
  screenshot("plan_shopping")
  find_all(IvlChoosePlan.select_plan_btn)[0].click
end

When(/^the individual selects a non silver plan on Plan Shopping page$/) do
  find_all(IvlChoosePlan.select_plan_btn)[0].click
end


And(/^I click confirm on the plan selection page for (.*)$/) do |named_person|
  find('.interaction-choice-control-value-terms-check-thank-you').click
  person = people[named_person]
  fill_in IvlConfirmYourPlanSelection.first_name, :with => (person[:first_name])
  fill_in IvlConfirmYourPlanSelection.last_name, :with => (person[:last_name])
  click_link "Confirm"
end

And(/I select a non silver plan on plan shopping page/) do
  find(IvlChoosePlan.select_plan_btn)[0].click
  screenshot("aptc_setamount")
end

Then(/the individual should see the modal pop up for eligibility/) do
  expect(page).to have_content IvlChoosePlan.non_silver_plan_modal_text
end

And(/^Individual clicks on purchase button on confirmation page$/) do
  find(IvlConfirmYourPlanSelection.i_agree_checkbox).click
  fill_in IvlConfirmYourPlanSelection.first_name, :with => "Patrick"
  fill_in IvlConfirmYourPlanSelection.last_name, :with => "Doe"
  find(IvlConfirmYourPlanSelection.confirm_btn).click
end

Then(/^.+ should see the extended APTC confirmation message/) do
  expect(page).to have_content("I must file a federal income tax return")
end

And(/^.+ clicks on the Continue button to go to the Individual home page/) do
  if page.has_link?('CONTINUE')
    click_link "CONTINUE"
  else
    click_link "GO TO MY ACCOUNT"
  end
  sleep 10
end

And(/I should see the individual home page/) do
  sleep 5
  expect(page).to have_content "My #{EnrollRegistry[:enroll_app].setting(:short_name).item}"
  # screenshot("my_account")
  # something funky about these tabs in JS
  # click_link "Documents"
  # click_link "Manage Family"
  # click_link "My #{EnrollRegistry[:enroll_app].setting(:short_name).item}"
end

Then(/^Individual clicks on Add New Person$/) do
  find(IvlFamilyInformation.add_new_person).click
end

And(/^Admin updates the address to Non DC Address$/) do
  sleep 2
  find(IvlHomepage.manage_family_btn).click
  sleep 2
  find(IvlManageFamilyPage.personal_tab).click
  find(AdminHomepage.remove_mailing_address).click
  find(EmployeeFamilyInformation.save_btn).click
  find('select[name="person[addresses_attributes][0][state]"]').click
  find(AdminHomepage.non_dc_state).click
  sleep 2
  fill_in IvlPersonalInformation.zip, with: '30043'
  find(EmployeeFamilyInformation.save_btn).click
  find(EmployeeHomepage.my_dc_health_link).click
end

And(/Admin clicks on shop for employer sponsored insurance/) do
  find(AdminHomepage.shop_for_employer).click
end

And(/Admin should not see the error text related to non dc address/) do
  expect(page).not_to have_content(AdminHomepage.failed_validation_text)
end

Then(/^Individual fills in the form$/) do
  fill_in IvlFamilyInformation.dependent_first_name, :with => (@u.first_name :first_name)
  fill_in IvlFamilyInformation.dependent_last_name, :with => (@u.last_name :last_name)
  fill_in 'jq_datepicker_ignore_dependent[dob]', :with => (@u.adult_dob :dob)
  click_link(@u.adult_dob.to_date.day)
  click_outside_datepicker(l10n('family_information').to_s)
  fill_in IvlFamilyInformation.dependent_ssn, :with => (@u.ssn :ssn)
  find(IvlFamilyInformation.dependent_relationship_dropdown).click
  find(:xpath, "//div[@class='selectric-scroll']/ul/li[contains(text(), 'Sibling')]").click
  find(IvlFamilyInformation.male_radiobtn).click
  find(IvlFamilyInformation.us_citizen_or_national_yes_radiobtn).click
  find(IvlFamilyInformation.naturalized_citizen_no_radiobtn).click
  find(IvlFamilyInformation.american_or_alaskan_native_no_radiobtn).click
  find(IvlFamilyInformation.incarcerated_no_radiobtn).click
end

Then(/Individual confirms dependent info/) do
  find(IvlFamilyInformation.confirm_member_btn).click
  sleep 5
end

Then(/Individual should see three dependents on the page/) do
  expect(find_all('.dependent_list').count).to eq 3
end

Then(/^Individual adds address for dependent$/) do
  find(IvlFamilyInformation.lives_with_prim_subs_checkbox).click
  fill_in IvlFamilyInformation.address_line_one, :with => '36 Campus Lane'
  fill_in IvlFamilyInformation.city, :with => 'Washington'
  find(IvlFamilyInformation.select_state_dropdown).click
  find(:xpath, "//div[@class='selectric-scroll']/ul/li[contains(text(), 'DC')]").click
  fill_in IvlFamilyInformation.zip, :with => "20002"
  find(IvlFamilyInformation.confirm_member_btn).click
  find('.btn', text: 'CONTINUE').click
end

And(/I click to see my Secure Purchase Confirmation/) do
  wait_and_confirm_text(/Messages/)
  @browser.link(text: /Messages/).click
  wait_and_confirm_text(/Your Secure Enrollment Confirmation/)
end

When(/^I visit the Insured portal$/) do
  visit "/"
  click_link 'Consumer/Family Portal'
end

When(/^the user visits the Insured portal$/) do
  visit "/"
  click_link 'Consumer/Family Portal'
end

Then(/Second user creates an individual account$/) do
  @browser.button(class: /interaction-click-control-create-account/).wait_until_present
  @browser.text_field(class: /interaction-field-control-user-email/).set(@u.email(:email2))
  @browser.text_field(class: /interaction-field-control-user-password/).set("aA1!aA1!aA1!")
  @browser.text_field(class: /interaction-field-control-user-password-confirmation/).set("aA1!aA1!aA1!")
  # screenshot("create_account")
  scroll_then_click(@browser.input(value: "Create account"))
end

Then(/^Second user goes to register as individual/) do
  step "user should see your information page"
  step "user goes to register as an individual"
  @browser.text_field(class: /interaction-field-control-person-first-name/).set("Second")
  @browser.text_field(class: /interaction-field-control-person-ssn/).set(@u.ssn(:ssn2))
end

Then(/^Second user should see a form to enter personal information$/) do
  step "Individual should see a form to enter personal information"
  @browser.text_field(class: /interaction-field-control-person-emails-attributes-0-address/).set(@u.email(:email2))
end

Then(/Individual asks for help$/) do
  expect(page).to have_content "Help"
  find('.container div.btn', text: 'Help').click
  wait_for_ajax
  expect(page).to have_content "Help"
  find(:id => "CSR", :wait => 10).click
  wait_for_ajax(5,2.5)
  sleep(2)
  expect(page).to have_content "First Name"
  #TODO: bombs on help_first_name sometimes
  fill_in "help_first_name", with: "Sherry"
  fill_in "help_last_name", with: "Buckner"
  sleep(2)
  # screenshot("help_from_a_csr")
  find("#search_for_plan_shopping_help").click
  find(".interaction-click-control-×").click
end

And(/^the Continue button is visible on the Account Setup page/i) do
  continue_button = find(IvlPersonalInformation.continue_btn_2)
  expect(continue_button).to be_visible
end

And(/^.+ clicks? on the Continue button of the Account Setup page$/i) do
  wait_for_ajax
  find(IvlPersonalInformation.continue_btn_2, wait: 10).click
end

Then(/^.+ sees the Verify Identity Consent page/)  do
  wait_and_confirm_text(/Verify Identity/)
end

When(/^a CSR exists/) do
  p = FactoryBot.create(:person, :with_csr_role, first_name: "Sherry", last_name: "Buckner")
  sleep 2 # Need to wait on factory
  FactoryBot.create(:user, email: "sherry.buckner@dc.gov", password: "aA1!aA1!aA1!", password_confirmation: "aA1!aA1!aA1!", person: p, roles: ["csr"])
end

When(/^CSR accesses the HBX portal$/) do
  visit '/'
  click_link 'HBX Portal'

  find('.interaction-click-control-sign-in-existing-account').click
  fill_in SignIn.username, :with => "sherry.buckner@dc.gov"
  find('#user_email').set("sherry.buckner@dc.gov")
  fill_in SignIn.password, :with => "aA1!aA1!aA1!"
  find('.interaction-click-control-sign-in').click
end

Then(/CSR should see the Agent Portal/) do
  expect(page).to have_content("a Trained Expert")
end

Then(/CSR opens the most recent Please Contact Message/) do
  expect(page).to have_content "Please contact"
  find(:xpath,'//*[@id="message_list_form"]/table/tbody/tr[2]/td[4]/a[1]').click
  sleep 1
  translation_interpolated_keys = {
    first_name: consumer.person.first_name,
    last_name: consumer.person.last_name,
    insured_email: consumer.email,
    href_root: "Assist Customer",
    site_home_business_url: EnrollRegistry[:enroll_app].setting(:home_business_url).item,
    site_short_name: site_short_name,
    contact_center_phone_number: EnrollRegistry[:enroll_app].settings(:contact_center_short_number).item.to_s,
    contact_center_tty_number: EnrollRegistry[:enroll_app].setting(:contact_center_tty_number).item.to_s
  }
  expect(page).to have_content(l10n("inbox.agent_assistance_secure_message", translation_interpolated_keys).html_safe.to_s[0..10])
end

Then(/CSR clicks on Resume Application via phone/) do
  expect(page).to have_content "Assist Customer"
  click_link "Assist Customer"
end

When(/CSR clicks on the header link to return to CSR page/) do
  expect(page).to have_content "I'm a Trained Expert", :wait => 10
  find(:xpath, "//a[text()[contains(.,' a Trained Expert')]]").click
end

Then(/CSR clicks on New Consumer Paper Application/) do
  find_link("New Consumer Paper Application")
  click_link "New Consumer Paper Application"
end

Then(/CSR starts a new enrollment/) do
  wait_for_ajax
  sleep(4)
  expect(page).to have_content('Personal Information')
end

Then(/^click continue again$/) do
  wait_and_confirm_text(/continue/i)

  scroll_then_click(@browser.a(text: /continue/i))
end

Given(/^\w+ visits the Employee portal$/) do
  visit '/'
  click_link 'Employee Portal'
  # screenshot("start")
  click_button 'Create account'
end

Then(/^(\w+) creates a new account$/) do |person|
  find('.interaction-click-control-create-account').click
  fill_in 'user[email]', with: "email#{person}"
  fill_in CreateAccount.password, with: "aA1!aA1!aA1!"
  fill_in CreateAccount.password_confirmation, with: "aA1!aA1!aA1!"
  click_button 'Create account'
end

And(/the consumer creates a new account with email$/) do |person|
  fill_in 'user[email]', with: "email#{person}"
  fill_in CreateAccount.password, with: "aA1!aA1!aA1!"
  fill_in CreateAccount.password_confirmation, with: "aA1!aA1!aA1!"
  find(CreateAccount.create_account_btn).click
end

When(/^\w+ clicks continue$/) do
  find(IvlChooseCoverage.continue_btn).click
end

When(/the consumer clicks on the privacy continue button$/) do
  find('.interaction-click-control-continue').click
end

When(/^\w+ selects Company match for (\w+)$/) do |company|
  expect(page).to have_content(company)
  find('#btn-continue').click
end

When(/^\w+ sees the (.*) page$/) do |title|
  expect(page).to have_content(title)
end

When(/^\w+ visits the Consumer portal$/i) do
  step "I visit the Insured portal"
end

When(/^(\w+) signs in$/) do |person|
  click_link 'Sign In'
  fill_in SignIn.username, with: "email#{person}"
  find('#user_email').set "email#{person}"
  fill_in SignIn.password, with: "aA1!aA1!aA1!"
  click_button 'Sign in'
end

Given(/^Company Tronics is created with benefits$/) do
  step "I visit the Employer portal"
  step "Tronics creates an HBX account"
  step "Tronics should see a successful sign up message"
  step "I should click on employer portal"
  step "Tronics creates a new employer profile with default_office_location"
  step "Tronics creates and publishes a plan year"
  step "Tronics should see a published success message without employee"
end

Then(/^(\w+) enters person search data$/) do |insured|
  step "#{insured} sees the Personal Information page"
  person = people[insured]
  fill_in "person[first_name]", with: person[:first_name]
  fill_in "person[last_name]", with: person[:last_name]
  fill_in "jq_datepicker_ignore_person[dob]", with: person[:dob]
  fill_in IvlPersonalInformation.ssn, with: person[:ssn]
  find(:xpath, '//label[@for="radio_female"]').click
  click_button 'CONTINUE'
end

Then(/^\w+ continues$/) do
  find(IvlChooseCoverage.continue_btn).click
end

Then(/^\w+ continues again$/) do
  find(IvlChooseCoverage.continue_btn).click
end

Then(/^\w+ enters demographic information$/) do
  step "Individual should see a form to enter personal information"
  fill_in 'person[emails_attributes][0][address]', with: "user#{rand(1000)}@example.com"
end

And(/^\w+ is an Employee$/) do
  wait_and_confirm_text(/Employer/i)
end

And(/^\w+ is a Consumer$/) do
  wait_and_confirm_text(/Verify Identity/i)
end

And(/(\w+) clicks on the purchase button on the confirmation page/) do |insured|
  person = people[insured]
  click_when_present(@browser.checkbox(class: /interaction-choice-control-value-terms-check-thank-you/))
  @browser.text_field(class: /interaction-field-control-first-name-thank-you/).set(person[:first_name])
  @browser.text_field(class: /interaction-field-control-last-name-thank-you/).set(person[:last_name])
  # screenshot("purchase")
  click_when_present(@browser.a(text: /confirm/i))
end


Then(/^the user creates a Consumer role account$/) do
  fill_in CreateAccount.email_or_username, :with => "aptc@dclink.com"
  fill_in CreateAccount.password, :with => "aA1!aA1!aA1!"
  fill_in CreateAccount.password_confirmation, :with => "aA1!aA1!aA1!"
  screenshot("create_account")
  find(CreateAccount.create_account_btn).click
end

Then(/^Aptc user goes to register as individual/) do
  step "user should see your information page"
  step "user goes to register as an individual"
  fill_in IvlPersonalInformation.first_name, :with => "Aptc"
  fill_in IvlPersonalInformation.ssn, :with => (@u.ssn :ssn)
  screenshot("aptc_register")
end

Then(/^Aptc user should see a form to enter personal information$/) do
  sleep 1
  step "Individual should see a form to enter personal information"
  # screenshot("aptc_personal")
  find('.btn', text: 'CONTINUE').click
end

Then(/^taxhousehold info is prepared for aptc user$/) do
  person = User.find_by(email: 'aptc@dclink.com').person
  household = person.primary_family.latest_household

  start_on = Date.new(TimeKeeper.date_of_record.year, 1,1)
  future_start_on = Date.new(TimeKeeper.date_of_record.year + 1, 1,1)
  rating_address = person.rating_address
  application_period = start_on.beginning_of_year..start_on.end_of_year
  renewal_application_period = future_start_on.beginning_of_year..future_start_on.end_of_year
  rating_area = BenefitMarkets::Locations::RatingArea.rating_area_for(rating_address, during: start_on) || FactoryBot.create(:benefit_markets_locations_rating_area, active_year: start_on.year)
  service_area = BenefitMarkets::Locations::ServiceArea.service_areas_for(rating_address, during: start_on).first || FactoryBot.create(:benefit_markets_locations_service_area, active_year: start_on.year)
  renewal_rating_area = BenefitMarkets::Locations::RatingArea.rating_area_for(rating_address, during: future_start_on) || FactoryBot.create(:benefit_markets_locations_rating_area, active_year: future_start_on.year)
  renewal_service_area = BenefitMarkets::Locations::ServiceArea.service_areas_for(rating_address, during: future_start_on).first || FactoryBot.create(:benefit_markets_locations_service_area, active_year: future_start_on.year)

  current_premium_table = FactoryBot.build(:benefit_markets_products_premium_table, effective_period: application_period, rating_area: rating_area)
  current_product = BenefitMarkets::Products::Product.all.by_year(start_on.year).where(metal_level_kind: :silver).first
  current_product.service_area = service_area
  current_product.premium_tables = [current_premium_table]
  current_product.save

  renewal_premium_table = FactoryBot.build(:benefit_markets_products_premium_table, effective_period: renewal_application_period, rating_area: renewal_rating_area)
  future_product = BenefitMarkets::Products::Product.all.by_year(future_start_on.year).where(metal_level_kind: :silver).first
  future_product.service_area = renewal_service_area
  future_product.premium_tables = [renewal_premium_table]
  future_product.save

  if household.tax_households.blank?
    household.build_thh_and_eligibility(80, 0, start_on, current_product.id, 'Admin')
    household.build_thh_and_eligibility(80, 0, future_start_on, future_product.id, 'Admin')
    household.save!
  end
  benefit_sponsorship = HbxProfile.current_hbx.benefit_sponsorship
  benefit_sponsorship.benefit_coverage_periods.detect {|bcp| bcp.contains?(start_on)}.update_attributes!(slcsp_id: current_product.id)
  benefit_sponsorship.benefit_coverage_periods.detect {|bcp| bcp.contains?(future_start_on)}.update_attributes!(slcsp_id: future_product.id)
  # screenshot("aptc_householdinfo")
end

Then(/^taxhousehold info is prepared for aptc user with selected eligibility$/) do
  person = User.find_by(email: 'aptc@dclink.com').person
  household = person.primary_family.latest_household

  start_on = Date.new(TimeKeeper.date_of_record.year, 1,1)
  future_start_on = Date.new(TimeKeeper.date_of_record.year + 1, 1,1)
  current_product = BenefitMarkets::Products::Product.all.by_year(start_on.year).where(metal_level_kind: :silver).first
  future_product = BenefitMarkets::Products::Product.all.by_year(future_start_on.year).where(metal_level_kind: :silver).first

  if household.tax_households.blank?
    household.build_thh_and_eligibility(80, 73, start_on, current_product.id, 'Admin')
    household.build_thh_and_eligibility(80, 73, future_start_on, future_product.id, 'Admin')
    household.save!
  end
  benefit_sponsorship = HbxProfile.current_hbx.benefit_sponsorship
  benefit_sponsorship.benefit_coverage_periods.detect {|bcp| bcp.contains?(start_on)}.update_attributes!(slcsp_id: current_product.id)
  benefit_sponsorship.benefit_coverage_periods.detect {|bcp| bcp.contains?(future_start_on)}.update_attributes!(slcsp_id: future_product.id)
end

Then(/^multi tax household info is prepared for aptc user with selected eligibility$/) do
  person = User.find_by(email: 'aptc@dclink.com').person
  family = person.primary_family
  current_year = TimeKeeper.date_of_record.beginning_of_year
  future_year = Date.new(TimeKeeper.date_of_record.year + 1, 1,1)
  day_of_month = FinancialAssistanceRegistry[:enrollment_dates].settings(:application_new_year_effective_date_day_of_month).item
  month_of_year = FinancialAssistanceRegistry[:enrollment_dates].settings(:application_new_year_effective_date_month_of_year).item
  start_on = TimeKeeper.date_of_record > Date.new(current_year.year, month_of_year, day_of_month) ? future_year : current_year
  create_mthh_for_family_with_aptc_csr(family, start_on, '73')
end

Then(/^multi tax household info is prepared for aptc user with selected eligibility for future year$/) do
  person = User.find_by(email: 'aptc@dclink.com').person
  family = person.primary_family
  future_year = Date.new(TimeKeeper.date_of_record.year + 1, 1,1)
  create_mthh_for_family_with_aptc_csr(family, future_year, 73)
end

And(/has valid csr 73 benefit package without silver plans/) do
  create_csr_73_bp_without_silver_plans
  BenefitMarkets::Products::ProductRateCache.initialize_rate_cache!
end

And(/has valid csr 0 benefit package with silver plans/) do
  create_csr_0_bp_with_silver_plans
  BenefitMarkets::Products::ProductRateCache.initialize_rate_cache!
end

And(/the individual sets APTC amount/) do
  find('.interaction-field-control-elected-aptc').set("")
  fill_in IvlChoosePlan.aptc_monthly_amount, :with => "50.00"
  screenshot("aptc_setamount")
end

Then(/the individual clicks the Reset button/) do
  sleep 5
  find_all(IvlChoosePlan.reset_btn).first.click
end

Then(/the individual should see the original applied APTC amount/) do
  expect(find(IvlChoosePlan.aptc_monthly_amount_id).value).to eq('68.00')
end

And(/the individual is in the Plan Selection page/) do
  expect(page).to have_content IvlChoosePlan.choose_plan_text
end

Then(/the individual sees the new APTC tool UI changes/) do
  expect(page).to have_content IvlChoosePlan.aptc_tool_available_text
  expect(page).to have_content IvlChoosePlan.aptc_tool_apply_monthly_text
  screenshot("aptc_setamount")
end

And(/the individual selects a silver plan on Plan Shopping page/) do
  binding.irb
  find_all(IvlChoosePlan.select_plan_btn)[1].click
end

Then(/the individual should see the elected APTC amount and click on the Confirm button of the Thank You page/) do
  wait_for_ajax
  expect(page).to have_content '$50.00'
  find(IvlConfirmYourPlanSelection.i_agree_checkbox).click
  fill_in IvlConfirmYourPlanSelection.first_name, :with => "Patrick"
  fill_in IvlConfirmYourPlanSelection.last_name, :with => "Doe"
  screenshot("aptc_purchase")
  sleep 2
  find(IvlConfirmYourPlanSelection.confirm_btn).click
end

Then(/the individual should see the APTC amount on the Receipt page/) do
  expect(page).to have_content IvlEnrollmentSubmitted.enrollment_submitted_text
  expect(page).to have_content '$50.00'
  screenshot("aptc_receipt")
end

Then(/the individual should see the elected aptc amount applied to enrollment in the Individual home page/) do
  wait_for_ajax
  expect(page).to have_content "My #{EnrollRegistry[:enroll_app].setting(:short_name).item}"
  expect(page).to have_content '$50.00'
  expect(page).to have_content IvlHomepage.aptc_amount_text
  screenshot("my_account")
end

And(/^consumer is an indian_tribe_member$/) do
  user.person.update_attributes!(tribal_state: 'ME')
end

Given(/^site is for (.*)$/) do |state|
  allow(EnrollRegistry[:enroll_app].setting(:state_abbreviation)).to receive(:item).and_return(state.upcase)
end

And(/^the consumer should see tribal name textbox without text$/) do
  wait_for_ajax
  expect(page).to have_selector("#tribal-name", text: '')
end

And(/consumer has successful ridp/) do
  user.identity_final_decision_code = "acc"
  user.save
  FactoryBot.create(:qualifying_life_event_kind, market_kind: "individual")
  hbx_profile = FactoryBot.create(:hbx_profile, :no_open_enrollment_coverage_period)
  BenefitMarkets::Products::ProductRateCache.initialize_rate_cache!
  start_on = TimeKeeper.date_of_record
  current_product = BenefitMarkets::Products::Product.all.by_year(start_on.year).where(metal_level_kind: :silver).first
  benefit_sponsorship = hbx_profile.benefit_sponsorship
  benefit_sponsorship.benefit_coverage_periods.detect {|bcp| bcp.contains?(start_on)}.update_attributes!(slcsp_id: current_product.id)
  user.person.consumer_role.update!(identity_validation: 'valid')
end

And(/products are marked as hc4cc/) do
  BenefitMarkets::Products::Product.all.each { |p| p.update!(is_hc4cc_plan: true) }
end

And(/consumer has osse eligibility/) do
  person = Person.all.first
  person.consumer_role.eligibilities << FactoryBot.build(:ivl_osse_eligibility, :with_admin_attested_evidence, evidence_state: :approved)
  current_date = TimeKeeper.date_of_record
  effective_on = ::Insured::Factories::SelfServiceFactory.find_enrollment_effective_on_date(current_date.in_time_zone('Eastern Time (US & Canada)'), current_date).to_date
  if effective_on.year != current_date.year

    renewal_eligibility = FactoryBot.build(:ivl_osse_eligibility,
                                           :with_admin_attested_evidence,
                                           evidence_state: :approved,
                                           key: :"aca_ivl_osse_eligibility_#{effective_on.year}".to_sym,
                                           effective_on: effective_on)
    person.consumer_role.eligibilities << renewal_eligibility
  end
end

When(/consumer visits home page after successful ridp/) do
  user.identity_final_decision_code = "acc"
  user.save
  user.person.consumer_role.update!(identity_validation: 'valid')
  FactoryBot.create(:qualifying_life_event_kind, market_kind: "individual")
  FactoryBot.create(:hbx_profile, :no_open_enrollment_coverage_period)
  BenefitMarkets::Products::ProductRateCache.initialize_rate_cache!
  visit "/families/home"
end

And(/current user visits the family home page/) do
  visit "/families/home"
end

And(/consumer clicked on "Married" qle/) do
  click_link "Married"
end

When(/.+ visits home page/) do
  visit "/families/home"
end

When(/^\w+ checks? the Insured portal open enrollment dates$/) do
  current_day = TimeKeeper.date_of_record
  if (Date.new(current_day.year - 1, 11, 1)..Date.new(current_day.year, 1, 31)).include?(current_day)
    expect(page).to have_content "Confirm Your Plan Selection"
  else
    next_year_date = current_day.next_year
    bcp = HbxProfile.current_hbx.benefit_sponsorship.benefit_coverage_periods.first
    bcp.update_attributes!(open_enrollment_start_on: Date.new(current_day.year - 1, 11, 1),
                           open_enrollment_end_on: Date.new(current_day.year, 1, 31))
    successor_bcp = bcp.successor
    successor_bcp.update_attributes!(open_enrollment_start_on: (current_day - 10.days),
                                     open_enrollment_end_on: Date.new(next_year_date.year, 1, 31))
  end
end

Then(/^.+should see a new renewing enrollment title on home page$/) do
  current_day = TimeKeeper.date_of_record
  effective_year = Family.application_applicable_year
  if (Date.new(effective_year - 1, 11, 1)..Date.new(effective_year, 1, 31)).include?(current_day)
    expect(page).to have_content effective_year
    expect(page).not_to have_content "Auto Renewing"
  else
    expect(page).to have_content "Auto Renewing"
  end
end

When(/^Incarcerated field is nil for the consumer$/) do
  user.person.update_attributes(is_incarcerated: nil)
end

When(/^citizen status is false for the consumer$/) do
  user.person.update_attributes(citizen_status: "not_lawfully_present_in_us")
end

Then(/^the consumer should see a message with incarcerated error$/) do
  expect(page).to have_content(/Incarceration question must be answered/)
end

When(/^DOB is nil for the consumer$/) do
  user.person.update_attributes(dob: nil)
  user.person.save(validate: false)
end

Then(/^the consumer should see a message with dob error$/) do
  expect(page).to have_content(/dob - must be filled/)
end

And(/Individual sees Your Information page$/) do
  expect(page).to have_content YourInformation.your_information_text
  find(YourInformation.continue_btn).click
end

When(/^Individual select a future qle date$/) do
  expect(page).to have_content "Married"
  fill_in "qle_date", :with => (TimeKeeper.date_of_record + 5.days).strftime("%m/%d/%Y")
  click_link "CONTINUE"
end

Then(/^Individual should see not qualify message$/) do
  expect(page).to have_content "The date you submitted does not qualify for special enrollment"
end

Then(/^Individual should see confirmation and continue$/) do
  find_all('.interaction-click-control-continue')[0].click
  expect(page).to have_content "Based on the information you entered, you may be eligible to enroll now but there is limited time"
  find_all('.interaction-click-control-continue')[0].click
end

Then(/^Individual should see successful sep message$/) do
  expect(page).to have_content "Based on the information you entered, you may be eligible to enroll now but there is limited time"
end

When(/^Individual clicks on Make Changes from Actions tab$/) do
  find(IvlHomepage.actions_dropdown).click
  find(IvlHomepage.make_changes_btn).click
end

When(/^Individual click on shop for new plan button on household info page$/) do
  click_link "Continue"
  sleep 5
  click_button "Shop for new plan"
end

When(/Individual clicks on None of the situations listed above apply checkbox$/) do
  sleep 2
  expect(page).to have_content 'None of the situations listed above apply'
  find(IvlSpecialEnrollmentPeriod.none_apply_checkbox).click
  expect(page).to have_content 'To enroll before Open Enrollment'
end

Then(/Individual should land on Home page$/) do
  sleep 1
  expect(page).to have_content "My #{EnrollRegistry[:enroll_app].setting(:short_name).item}"
end

When(/Individual clicks on Go To My Account button$/) do
  click_link "GO TO MY ACCOUNT"
end

When(/Individual clicks on continue button on Choose Coverage page$/) do
  wait_for_ajax
  find(IvlChooseCoverage.continue_btn).click
end

And(/Individual clicks the Back to My Account button$/) do
  find(".interaction-click-control-back-to-my-account")
end

And(/Individual signed in to resume enrollment$/) do
  visit '/'
  click_link('Consumer/Family Portal', wait: 10)
  sleep 2
  find('.interaction-click-control-sign-in').click
  sleep 5
  fill_in SignIn.username, :with => "testflow@test.com"
  fill_in SignIn.password, :with => "aA1!aA1!aA1!"
  find(SignIn.sign_in_btn).click
end

Then(/Individual creates a new HBX account via username$/) do
  fill_in CreateAccount.email_or_username, :with => "testflow"
  fill_in CreateAccount.password, :with => "aA1!aA1!aA1!"
  fill_in CreateAccount.password_confirmation, :with => "aA1!aA1!aA1!"
  find(CreateAccount.create_account_btn).click
end

When(/Individual creates an HBX account with username already in use$/) do
  fill_in CreateAccount.email_or_username, :with => "testflow"
  fill_in CreateAccount.password, :with => "aA1!aA1!aA1!"
  fill_in CreateAccount.password_confirmation, :with => "aA1!aA1!aA1!"
  find(CreateAccount.create_account_btn).click
end

When(/Individual creates an HBX account with email already in use$/) do
  fill_in CreateAccount.email_or_username, :with => "testflow@test.com"
  fill_in CreateAccount.password, :with => "aA1!aA1!aA1!"
  fill_in CreateAccount.password_confirmation, :with => "aA1!aA1!aA1!"
  find(CreateAccount.create_account_btn).click
end

Then(/Dependent creates a new HBX account$/) do
  fill_in CreateAccount.email_or_username, :with => "testtest@gmail.com"
  fill_in CreateAccount.password, :with => "aA1!aA1!aA1!"
  fill_in CreateAccount.password_confirmation, :with => "aA1!aA1!aA1!"
  find(CreateAccount.create_account_btn).click
end

When(/Dependent registers as an individual$/) do
  fill_in IvlPersonalInformation.first_name, :with => "Spouse"
  fill_in IvlPersonalInformation.last_name, :with => "Smith"
  fill_in IvlPersonalInformation.dob, :with => "11/11/1989"
  fill_in IvlPersonalInformation.ssn, :with => "212-31-3000"
  find(IvlPersonalInformation.male_radiobtn).click
  screenshot("register")
  find(IvlPersonalInformation.continue_btn).click
end

Then(/^Individual adds spouse dependent info$/) do
  fill_in IvlFamilyInformation.dependent_first_name, :with => "Spouse"
  fill_in IvlFamilyInformation.dependent_last_name, :with => "Smith"
  fill_in IvlFamilyInformation.dependent_dob, :with => "11/11/1989"
  click_outside_datepicker(l10n('family_information').to_s)
  fill_in IvlFamilyInformation.dependent_ssn, :with => "212-31-3000"
  find(IvlFamilyInformation.dependent_relationship_dropdown).click
  find(IvlFamilyInformation.spouse).click
  find(IvlFamilyInformation.female_radiobtn).click
  find(IvlFamilyInformation.us_citizen_or_national_yes_radiobtn).click
  find(IvlFamilyInformation.naturalized_citizen_no_radiobtn).click
  find(IvlFamilyInformation.american_or_alaskan_native_no_radiobtn).click
  find(IvlFamilyInformation.incarcerated_no_radiobtn).click
end

And(/^Dependent clicks on purchase button on confirmation page$/) do
  find(IvlConfirmYourPlanSelection.i_agree_checkbox).click
  fill_in IvlConfirmYourPlanSelection.first_name, :with => "Spouse"
  fill_in IvlConfirmYourPlanSelection.last_name, :with => "Smith"
  click_link "Confirm"
end

Given(/^the warning duplicate enrollment feature configuration is enabled$/) do
  allow(EnrollRegistry[:existing_coverage_warning].feature).to receive(:is_enabled).and_return(true)
end

And(/Dependent sees Your Information page$/) do
  expect(page).to have_content YourInformation.your_information_text
  find(YourInformation.continue_btn).click
end

And(/Individual should see Duplicate Enrollment warning in the Confirmation page$/) do
  expect(page.has_css?(IvlConfirmYourPlanSelection.dup_enrollment_warning_1)).to eq true
  expect(page.has_css?(IvlConfirmYourPlanSelection.dup_enrollment_warning_2)).to eq true
end

And(/^Primary member logs back in$/) do
  wait_for_ajax
  find(CreateAccount.sign_in_link).click
  fill_in SignIn.username, :with => "testflow@test.com"
  fill_in SignIn.password, :with => "aA1!aA1!aA1!"
  find('.interaction-click-control-sign-in').click
end
When(/Individual creates an HBX account with SSN already in use$/) do
  fill_in CreateAccount.email_or_username, :with => "testflow123"
  fill_in CreateAccount.password, :with => "aA1!aA1!aA1!"
  fill_in CreateAccount.password_confirmation, :with => "aA1!aA1!aA1!"
  click_button "Create Account"
  find(YourInformation.continue_btn).click
  fill_in IvlPersonalInformation.first_name, with: "Jack"
  fill_in IvlPersonalInformation.last_name, with: "Smith"
  fill_in IvlPersonalInformation.dob, with: "11/11/1992"
  fill_in IvlPersonalInformation.ssn, with: '212-31-3131'
  find(IvlPersonalInformation.male_radiobtn).click
  find(IvlPersonalInformation.need_coverage_yes).click
  find(IvlPersonalInformation.continue_btn).click
end

When(/Individual fills in personal info$/) do
  fill_in IvlPersonalInformation.first_name, with: "Jack"
  fill_in IvlPersonalInformation.last_name, with: "Smith"
  fill_in IvlPersonalInformation.dob, with: "11/11/1992"
  fill_in IvlPersonalInformation.ssn, with: '212-31-3131'
  find(IvlPersonalInformation.male_radiobtn).click
  find(IvlPersonalInformation.need_coverage_yes).click
end

When(/Individual clicks the personal info continue button$/) do
  find(IvlPersonalInformation.continue_btn).click
end

And(/the extended_aptc_individual_agreement_message configuration is enabled/) do
  enable_feature :extended_aptc_individual_agreement_message
end

Given(/plan filter feature is disabled and osse subsidy feature is enabled/) do
  year = TimeKeeper.date_of_record.year
  allow(EnrollRegistry[:aca_ivl_osse_eligibility].feature).to receive(:is_enabled).and_return(true)
  allow(EnrollRegistry["aca_ivl_osse_eligibility_#{year}".to_sym].feature).to receive(:is_enabled).and_return(true)
  allow(EnrollRegistry["aca_ivl_osse_eligibility_#{year - 1}".to_sym].feature).to receive(:is_enabled).and_return(true)
  allow(EnrollRegistry["aca_ivl_osse_eligibility_#{year + 1}".to_sym].feature).to receive(:is_enabled).and_return(true)
  allow(EnrollRegistry[:individual_osse_plan_filter].feature).to receive(:is_enabled).and_return(false)
end

Then(/consumer should see 0 premiums for all plans/) do
  page.all("h2.plan-premium").each do |premium|
    expect(premium).to have_content("$0.00")
  end
end

Then(/the continue button has a data disabled attribute$/) do
  continue_button = find('a.btn.btn-lg.btn-primary.btn-block', visible: false)['data-disable-with']
  expect(continue_button).to eql('Continue')
end

And(/^the Continue button is visible on Account Setup page/i) do
  continue_button = find('a.interaction-click-control-continue')
  expect(continue_button).to be_visible
end
