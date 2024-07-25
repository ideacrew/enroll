# frozen_string_literal: true

When(/^Individual market is not under open enrollment period$/) do
  visit "/"
  find(HomePage.consumer_family_portal_btn).click
  FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period)
  FactoryBot.create(:qualifying_life_event_kind, market_kind: "individual")
  FactoryBot.create(:qualifying_life_event_kind, :effective_on_event_date_and_first_month, market_kind: "individual")
  BenefitMarkets::Products::ProductRateCache.initialize_rate_cache!
  r_id = BenefitMarkets::Products::Product.all.where(title:  "IVL Test Plan Bronze")[1].id.to_s
  BenefitMarkets::Products::Product.all.where(title:  "IVL Test Plan Bronze")[0].update_attributes!(renewal_product_id: r_id)
end

And(/there exists (.*) with active individual market role and verified identity$/) do |named_person|
  consumer_with_verified_identity(named_person)
end

And(/(.*) logged into the consumer portal$/) do |named_person|
  person = people[named_person]
  person_rec = Person.where(first_name: person[:first_name], last_name: person[:last_name]).first
  login_as person_rec.user
  visit 'families/home'
end

Then(/^(.*) clicks continue from qle$/) do |_name|
  expect(page).to have_content "Based on the information you entered, you may be eligible to enroll now but there is limited time"
  click_button "Continue"
end

Then(/(.*) clicks Back to my account button$/) do |_name|
  find('.btn.btn-primary.interaction-click-control-back-to-my-account').click
end

And(/^Patrick Doe clicks on back to my account button$/) do
  find('.interaction-click-control-back-to-my-account').click
end

Then(/(.*) should land on Home page and should see Shop for Plans Banner$/) do |_name|
  sleep 2
  expect(page).to have_content(/You are eligible to enroll or change coverage/)
end

When(/(.*) click the "(.*?)" in qle carousel/) do |_name, qle_event|
  expect(page).to have_content(qle_event, wait: 10)
  click_link qle_event.to_s
end

When(/(.*) clicks browser back button/) do |_name|
  @browser.execute_script('window.history.back()')
end

Then(/(.*) should redirect to receipt page/) do |_name|
  expect(page).to have_content("Enrollment Submitted")
end

Then(/(.*) should see family members page and clicks continue/) do |_name|
  expect(page).to have_content l10n('family_information').to_s
  find('#dependent_buttons .interaction-click-control-continue', :wait => 5).click
end

When(/^(.*) selects a past qle date$/) do |_name|
  expect(page).to have_content "Married"
  fill_in "qle_date", :with => (TimeKeeper.date_of_record - 5.days).strftime("%m/%d/%Y")
  click_link((TimeKeeper.date_of_record - 5.days).day)
  within '#qle-date-chose' do
    click_link "CONTINUE"
  end
end

Given(/an individual has gender information as male/) do
  gender = Person.first.gender
  gender == 'male'
end

And(/the individual selects gender as female/) do
  find(IvlPersonalInformation.female_radiobtn).click
end

Then(/the individual should show gender as female/) do
  gender = Person.first.gender
  gender == 'female'
end

When(/individual has a home and mailing address/) do
  addresses = Person.first.addresses
  addresses.last.destroy
  addresses << FactoryBot.build(:address, :mailing_kind)
  addresses.last.save!
end

When(/individual removes mailing address/) do
  find(IvlPersonalInformation.remove_mailing_address_btn).click
end

When(/individual edits home address/) do
  fill_in IvlPersonalInformation.address_line_one, :with => "123 New St"
end

When(/individual saves personal information changes/) do
  find_all(IvlPersonalInformation.personal_save).first.click
end

Then(/information should be saved successfully/) do
  expect(find_all('.alert-notice').count).to eq 1
  expect(find_field(IvlPersonalInformation.address_line_one).value).to eq "123 New St"
end

Then(/Individual clicks yes and clicks continue/) do
  expect(page).to have_css('.special_qle_reasons')
  find(IvlPersonalInformation.reason_yes_radiobtn).click
  within '#qle_reason' do
    find('#qle_submit_reason').click
  end

end

Then(/Individual clicks no and clicks continue/) do
  expect(page).to have_css('.special_qle_reasons')
  find(IvlPersonalInformation.reason_no_radiobtn).click
  within '#qle_reason' do
    find('#qle_submit_reason').click
  end
end

Given(/is your health coverage expanded question is disable/) do
  disable_feature :is_your_health_coverage_ending_expanded_question
end

Given(/is your health coverage expanded question is enabled/) do
  enable_feature :is_your_health_coverage_ending_expanded_question
end

Then(/^.+ enter personal information with american indian alaska native status with featured tribe$/) do
  find(IvlPersonalInformation.us_citizen_or_national_yes_radiobtn).click
  find(IvlPersonalInformation.naturalized_citizen_no_radiobtn).click
  find(IvlPersonalInformation.american_or_alaskan_native_yes_radiobtn).click
  if EnrollRegistry[:bs4_consumer_flow].enabled?
    find(IvlPersonalInformation.tribe_state_dropdown).click
    find("#tribal-state-container .selectric-items li", text: EnrollRegistry[:enroll_app].setting(:state_abbreviation).item).click
    tribe_codes = find_all('input.tribe_codes')
    tribe_codes.first.click unless tribe_codes.empty?
  end
  find(IvlPersonalInformation.incarcerated_no_radiobtn).click
  fill_in IvlPersonalInformation.address_line_one, :with => "4900 USAA BLVD NE"
  fill_in IvlPersonalInformation.address_line_two, :with => "212"
  fill_in IvlPersonalInformation.city, :with => "Washington"
  find_all(IvlPersonalInformation.select_state_dropdown).first.click
  find_all(:xpath, "//li[contains(., '#{EnrollRegistry[:enroll_app].setting(:state_abbreviation).item}')]").last.click
  fill_in IvlPersonalInformation.zip, :with => EnrollRegistry[:enroll_app].setting(:contact_center_zip_code).item
  fill_in IvlPersonalInformation.home_phone, :with => "22075555555"
  sleep 2
end

Then(/^.+ enter personal information with american indian alaska native status with other tribe$/) do
  find(IvlPersonalInformation.us_citizen_or_national_yes_radiobtn).click
  find(IvlPersonalInformation.naturalized_citizen_no_radiobtn).click
  find(IvlPersonalInformation.american_or_alaskan_native_yes_radiobtn).click
  if EnrollRegistry[:bs4_consumer_flow].enabled?
    find(IvlPersonalInformation.tribe_state_dropdown).click
    find("#tribal-state-container .selectric-items li", text: EnrollRegistry[:enroll_app].setting(:state_abbreviation).item).click
    tribe_codes = find_all('input.tribe_codes')
    tribe_codes.last.click unless tribe_codes.empty?
    fill_in IvlPersonalInformation.tribal_name, :with => "testTribeName" unless tribe_codes.empty?
  end
  find(IvlPersonalInformation.incarcerated_no_radiobtn).click
  fill_in IvlPersonalInformation.address_line_one, :with => "4900 USAA BLVD NE"
  fill_in IvlPersonalInformation.address_line_two, :with => "212"
  fill_in IvlPersonalInformation.city, :with => "Washington"
  find_all(IvlPersonalInformation.select_state_dropdown).first.click
  find_all(:xpath, "//li[contains(., '#{EnrollRegistry[:enroll_app].setting(:state_abbreviation).item}')]").last.click
  fill_in IvlPersonalInformation.zip, :with => EnrollRegistry[:enroll_app].setting(:contact_center_zip_code).item
  fill_in IvlPersonalInformation.home_phone, :with => "22075555555"
  sleep 2
end

Then(/^the consumer will not see the Enrollments link$/) do
  expect(page).not_to have_selector(".interaction-click-control-enrollments")
end

When(/^the consumer manually enters the "Enrollment History Page" url in the browser search bar$/) do
  visit main_app.enrollment_history_insured_families_path
end

And(/^the Enrollments link is visible$/) do
  expect(page).to have_selector(".interaction-click-control-enrollments")
end

When(/^the consumer clicks the Enrollments link$/) do
  find(".interaction-click-control-enrollments").click
end

Then(/^the consumer will navigate to the Enrollment History page$/) do
  expect(page).to have_selector("#enrollment-history-title")
end

And(/^the user clicks the deleted messages button$/) do
  find(".interaction-click-control-deleted").click
end

When(/^bs4_consumer_flow feature is enabled$/) do
  allow(EnrollRegistry[:bs4_consumer_flow].feature).to receive(:is_enabled).and_return(true)
  enable_feature :contrast_level_aa
end

When(/^bs4_consumer_flow feature is disable$/) do
  disable_feature :bs4_consumer_flow
end