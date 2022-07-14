# frozen_string_literal: true


And(/^a financial assistance application and two applicants in info completed state exist$/) do
  create_completed_fa_application_with_two_applicants
end

When(/user clicks the Add New Person Button$/) do
  click_link "Add New Person"
end

And(/user enters applicant info WITHOUT tribal member us citizen or naturalization status and submits form$/) do
  fill_in FinancialAssistance::ApplicantForm.applicant_first_name, :with => 'johnson'
  fill_in FinancialAssistance::ApplicantForm.applicant_last_name, :with => 'smith'
  fill_in FinancialAssistance::ApplicantForm.applicant_form_dob, :with => '10/10/1984'
  #click_link(10)
  click_outside_datepicker(l10n('family_information'))
  fill_in FinancialAssistance::ApplicantForm.applicant_form_ssn, :with => '123456543'
  find("span", :text => "choose").click
  find(:xpath, FinancialAssistance::ApplicantForm.applicant_spouse_select).click
  find(:xpath, FinancialAssistance::ApplicantForm.applicant_form_gender_select_male).click
  find(:xpath, FinancialAssistance::ApplicantForm.is_applying_coverage_true).click
  # choose('radio_incarcerated_no', allow_label_click: true)
  # choose('indian_tribe_member_no', allow_label_click: true)
  # choose('applicant_us_citizen_true', allow_label_click: true)
  # choose('applicant_naturalized_citizen_false', allow_label_click: true)
  find(".btn", text: "CONFIRM MEMBER").click
end

And(/user will have to accept alert pop ups for missing fields$/) do
  sleep 1
  page.driver.browser.switch_to.alert.accept
  sleep 1
  page.driver.browser.switch_to.alert.accept
  sleep 1
  page.driver.browser.switch_to.alert.accept
end

Then(/the applicant should have been created successfully$/) do
  # Do this step better but you get the point
  sleep 2
  application.reload
  expect(application.applicants.where(first_name: "johnson", last_name: "smith").present?).to eq(true)
end

And(/user fills in the missing fields and clicks submit$/) do
  choose(FinancialAssistance::ApplicantForm.radio_incarcerated_no, allow_label_click: true)
  choose(FinancialAssistance::ApplicantForm.indian_tribe_no, allow_label_click: true)
  choose(FinancialAssistance::ApplicantForm.us_citizen_true, allow_label_click: true)
  choose(FinancialAssistance::ApplicantForm.naturalized_citizen_false, allow_label_click: true)
  find(".btn", text: "CONFIRM MEMBER").click
end

Given(/^at least two other household members exist$/) do
  click_link "Add New Person"

  fill_in 'applicant[first_name]', :with => 'johnson'
  fill_in 'applicant[last_name]', :with => 'smith'
  fill_in 'jq_datepicker_ignore_applicant[dob]', :with => '10/10/1984'
  #click_link(10)
  click_outside_datepicker("#{l10n('family_information')}")
  fill_in 'applicant[ssn]', :with => '123456543'
  find("span", :text => "choose").click
  find(:xpath, "//div[@class='selectric-scroll']/ul/li[contains(text(), 'Spouse')]").click
  find(:xpath, '//label[@for="radio_male"]').click
  find(:xpath, '//label[@for="is_applying_coverage_true"]').click
  choose('radio_incarcerated_no', allow_label_click: true)
  choose('indian_tribe_member_no', allow_label_click: true)
  choose('applicant_us_citizen_true', allow_label_click: true)
  choose('applicant_naturalized_citizen_false', allow_label_click: true)
  find(".btn", text: "CONFIRM MEMBER").click

  click_link "Add New Person"
  fill_in 'applicant[first_name]', :with => 'smity'
  fill_in 'applicant[last_name]', :with => 'johnson'
  fill_in 'jq_datepicker_ignore_applicant[dob]', :with => '10/10/2010'
  #click_link(10)
  click_outside_datepicker("#{l10n('family_information')}")
  fill_in 'applicant[ssn]', :with => '123456549'
  find("span", :text => "choose").click
  find(:xpath, "//div[@class='selectric-scroll']/ul/li[contains(text(), 'Child')]").click
  find(:xpath, '//label[@for="radio_male"]').click
  find(:xpath, '//label[@for="is_applying_coverage_true"]').click
  choose('radio_incarcerated_no', allow_label_click: true)
  choose('indian_tribe_member_no', allow_label_click: true)
  choose('applicant_us_citizen_true', allow_label_click: true)
  choose('applicant_naturalized_citizen_false', allow_label_click: true)
  find(".btn", text: "CONFIRM MEMBER").click

  sleep 1

  expect(page).to have_content('ADD INCOME & COVERAGE INFO', count: 3)
end

Given(/^that the user is on the FAA Family Relationships page$/) do
  page.should have_xpath('//*[@id="family-matrix"]/h1')
end


Then(/^View My Applications left section WILL display$/) do
  expect(page).to have_content('View My Applications')
end

Then(/^Review & Submit left section WILL display$/) do
  expect(page).to have_content('Review & Submit')
end

Given(/^there is a nil value for at least one relationship$/) do
  @target_fa_application.relationships.destroy_all
  visit page.current_path
  expect(find_all(:css, ".selectric .label").map{ |selector| selector.text }).to include("choose")
end

Then(/^the family member row will be highlighted$/) do
  expect(page).to have_css('.missing_relation')
end


When(/^the user populates the drop down with a value$/) do
  @relationship = find_all(:css, ".missing_relation").first
  @relationship.find("span", :text => "choose").click
  @relationship.find(:xpath, "//div[@class='selectric-scroll']/ul/li[contains(text(), 'Sibling')]").click
end


Then(/^the relationship is saved$/) do
  begin
    expect(@relationship.find(:css, ".selectric .label").text).to eq("Sibling")
  rescue Selenium::WebDriver::Error::StaleElementReferenceError
    sleep 10
    expect(@relationship.find(:css, ".selectric .label").text).to eq("Sibling")
  end
end

And(/^all the relationships have been entered$/) do
  find(IvlChooseCoverage.continue_btn).click
  expect(page).to have_no_css('.missing_relation')
  sleep 3
end

Then(/^the user will navigate to the Review & Submit page$/) do
  expect(page).to have_content("Review Your Application")
end