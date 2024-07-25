# frozen_string_literal: true

Given(/^that the user is on FAA Household Info: Family Members page$/) do
  login_as consumer, scope: :user
  hbx_profile = FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period)
  hbx_profile.benefit_sponsorship.benefit_coverage_periods.each do |bcp|
    ivl_product = FactoryBot.create(:benefit_markets_products_health_products_health_product, :ivl_product, application_period: (bcp.start_on..bcp.end_on))
    bcp.update_attributes!(slcsp_id: ivl_product.id)
  end
  visit root_path
  click_link 'Assisted Consumer/Family Portal'
  find('a[class*="interaction-click-control-continue"]').click
  sleep 2
  # Security Questions
  step 'the user answers all the VERIFY IDENTITY  questions'
  step "the consumer is RIDP verified"
  click_button 'Submit'
  find_all(IvlVerifyIdentity.continue_application_btn)[0].click
  page.all('label').detect { |l| l.text == 'Yes' }.click
  click_button 'CONTINUE'
  # should be on application year select page
  # TODO: Will need to be updated when year select logic implemented
  if EnrollRegistry.feature_enabled?(:iap_year_selection)
    find(IvlIapHelpPayingForCoverage.continue_btn).click
    sleep 2
  end
  click_link 'Continue'
end

Given(/^the applicant only has one home address and one mailing address$/) do
  application = FinancialAssistance::Application.where(family_id: consumer.person.primary_family.id).first
  applicant = application.primary_applicant
  home_address = applicant.addresses.where(kind: 'home').first
  other_address = applicant.addresses.where(:id.ne => home_address.id).first
  other_address.update_attributes(
    {
      kind: 'mailing',
      address_1: '123 Main St',
      address_2: 'Apt 1',
      city: 'Anytown',
      state: 'DC',
      zip: '20001'
    }
  )
end

And(/^the user clicks edit applicant$/) do
  find('.edit-applicant').click
end

And(/^the user sees Remove Mailing Address button$/) do
  expect(page).to have_css('#remove_applicant_mailing_address:not(.dn)')
end

And(/^the user clicks Remove Mailing Address button$/) do
  find('#remove_applicant_mailing_address').click
end

And(/^user clicks confirm member button$/) do
  find('#confirm_member').click
end

Then(/^user should not see the deleted mailing address$/) do
  expect(page).not_to have_content('123 Main St')
  expect(page).not_to have_content('Apt 1')
  expect(page).not_to have_content('Anytown')
  expect(page).not_to have_content('20001')
end

And(/^the user sees Add Mailing Address button$/) do
  expect(page).to have_css('#add_applicant_mailing_address:not(.dn)')
  expect(page).not_to have_css('#remove_applicant_mailing_address:not(.dn)')
end

When(/^at least one applicant is in the Info Needed state$/) do
  sleep 5
  expect(application.incomplete_applicants?).to be true
  expect(page).to have_content('Info Needed')
end

Then(/^the CONTINUE button will be disabled$/) do
  if page.find('#btn-continue')[:disabled]
    expect(page.find('#btn-continue')[:disabled]).to include("disabled")
  else
    expect(page.find('#btn-continue')[:class]).to include("disabled")
  end
end

Given(/^the primary member exists$/) do
  sleep 2
  expect(page).to have_content('SELF')
end

Given(/^NO other household members exist$/) do
  expect(application.active_applicants.count).to eq(1)
end

Then(/^Family Relationships left section will NOT display$/) do
  expect(page).to have_no_content('Family Relationships')
end

Given(/^at least one other household members exist$/) do
  sleep 2
  click_link "Add New Person"
  sleep 2
  fill_in "applicant_first_name", with: 'johnson'
  fill_in "applicant_last_name", with: 'smith'
  fill_in "family_member_dob_", with: '10/10/1984'
  fill_in "applicant_ssn", with: '123456543'
  find(:xpath, '//label[@for="radio_female"]').click
  #find(:xpath, '//form/div[1]/div[5]/div[2]/label[1]').click
  # Click label
  find('#new_applicant > div.house.col-md-12.col-sm-12.col-xs-12.no-pd > div:nth-child(5) > div.col-md-5.mt18 > label.static_label.label-floatlabel.mt-label').click
  find("span", :text => "choose").click
  find(:xpath, "//div[@class='selectric-scroll']/ul/li[contains(text(), 'Spouse')]").click

  choose('applicant_us_citizen_true', allow_label_click: true)
  choose('applicant_naturalized_citizen_false', allow_label_click: true)
  choose('indian_tribe_member_no', allow_label_click: true)
  choose('radio_incarcerated_no', allow_label_click: true)

  find(:xpath, '//label[@for="is_applying_coverage_true"]').click

  find(".btn", text: "CONFIRM MEMBER").click

  sleep 2
  expect(page).to have_content('ADD INCOME & COVERAGE INFO', count: 2)
  application.update!(aasm_state: "draft")
end

Given(/^a new household member is not applying$/) do
  click_link "Add New Person"
  sleep 2
  find(:xpath, '//label[@for="is_applying_coverage_false"]').click
end

Then(/^the new household member should not see consumer fields$/) do
  expect(page.has_css?(IvlManageFamilyPage.consumer_fields)).to eq false
end

Then(/^the no ssn warning will appear$/) do
  expect(page).to have_content("providing your SSN can be helpful")
end

Then(/^Family Relationships left section WILL display$/) do
  sleep 2
  if EnrollRegistry[:bs4_consumer_flow].enabled?
    expect(page).to have_content('FAMILY RELATIONSHIPS')
  else
    expect(page).to have_content('Family Relationships')
  end
end

When(/^primary applicant is in Info Completed state$/) do
  find(IvlIapFamilyInformation.add_income_and_coverage_info_btn).click
  find(IvlIapTaxInformationPage.file_taxes_no_radiobtn).click
  find(IvlIapTaxInformationPage.claimed_as_tax_dependent_no_radiobtn).click
  find(IvlIapTaxInformationPage.continue_btn).click
  find(IvlIapJobIncomeInformationPage.has_job_income_no_radiobtn).click
  find(IvlIapJobIncomeInformationPage.has_self_employee_income_no_radiobtn).click
  find(IvlIapJobIncomeInformationPage.continue_btn).click
  find(IvlIapOtherIncomePage.has_unemployment_income_no_radiobtn).click
  find(IvlIapOtherIncomePage.has_other_income_no_radiobtn).click
  find(IvlIapOtherIncomePage.continue_btn).click
  find(IvlIapIncomeAdjustmentsPage.income_adjustments_no_radiobtn).click
  find(IvlIapIncomeAdjustmentsPage.continue_btn).click
  find(IvlIapHealthCoveragePage.has_enrolled_health_coverage_no_radiobtn).click
  find(IvlIapHealthCoveragePage.has_eligible_health_coverage_no_radiobtn).click
  find(IvlIapHealthCoveragePage.has_eligible_medicaid_cubcare_false).click
  find(IvlIapHealthCoveragePage.has_eligibility_changed_false).click
  find(IvlIapHealthCoveragePage.continue).click
  find(IvlIapOtherQuestions.is_pregnant_no_radiobtn).click
  find(IvlIapOtherQuestions.is_post_partum_period_no_radiobtn).click
  find(IvlIapOtherQuestions.person_blind_no_radiobtn).click
  find(IvlIapOtherQuestions.has_daily_living_help_no_radiobtn).click
  find(IvlIapOtherQuestions.need_help_paying_bills_no_radiobtn).click
  find(IvlIapOtherQuestions.physically_disabled_no_radiobtn).click
  find('.interaction-choice-control-value-is-primary-caregiver-no').click
  find(IvlIapOtherQuestions.continue_to_next_step).click
end

When(/^all applicants are in Info Completed state$/) do
  until find_all(".btn", text: "ADD INCOME & COVERAGE INFO").empty?
    find_all(".btn", text: "ADD INCOME & COVERAGE INFO")[0].click
    # find("#is_required_to_file_taxes_yes").click
    sleep 10
    find("#is_required_to_file_taxes_no", wait: 10).click
    find("#is_claimed_as_tax_dependent_no", wait: 10).click
    find("#is_joint_tax_filing_no", wait: 10).click if page.all("#is_joint_tax_filing_no").present?
    find('input[id="btn-continue"]').click

    find("#has_job_income_false", wait: 10).click
    find("#has_self_employment_income_false", wait: 10).click
    find(:xpath, '//*[@id="btn-continue"]', wait: 10).click

    find("#has_unemployment_income_false", wait: 10).click if FinancialAssistanceRegistry[:unemployment_income].enabled?
    find("#has_other_income_false", wait: 10).click
    find(:xpath, '//*[@id="btn-continue"]', wait: 10).click
    find("#has_deductions_false", wait: 10).click
    find(:xpath, '//*[@id="btn-continue"]', wait: 10).click

    find("#has_enrolled_health_coverage_false", wait: 10).click

    find(IvlIapHealthCoveragePage.has_eligible_health_coverage_no_radiobtn, wait: 10).click
    find(:xpath, '//*[@id="btn-continue"]', wait: 10).click
    find(IvlIapOtherQuestions.is_pregnant_no_radiobtn, wait: 10).click
    find(IvlIapOtherQuestions.is_post_partum_period_no_radiobtn, wait: 10).click
    find("#is_self_attested_blind_no", wait: 10).click
    find("#has_daily_living_no", wait: 10).click
    find(IvlIapOtherQuestions.need_help_paying_bills_no_radiobtn, wait: 10).click
    find(IvlIapOtherQuestions.physically_disabled_no_radiobtn, wait: 10).click
    find(IvlIapOtherQuestions.continue_btn, wait: 10).click
  end
end

And(/^primary applicant completes application and marks they are required to file taxes$/) do
  find("#is_required_to_file_taxes_yes").click
  sleep 1
  find("#is_claimed_as_tax_dependent_no").click
  find("#is_joint_tax_filing_no").click if page.all("#is_joint_tax_filing_no").present?
  find('input[id="btn-continue"]').click

  find("#has_job_income_false").click
  find("#has_self_employment_income_false").click
  find(:xpath, '//*[@id="btn-continue"]').click

  find('#has_unemployment_income_false').click if FinancialAssistanceRegistry[:unemployment_income].enabled?
  find("#has_other_income_false").click
  find(:xpath, '//*[@id="btn-continue"]').click
  find("#has_deductions_false").click
  find(:xpath, '//*[@id="btn-continue"]').click

  find("#has_enrolled_health_coverage_false").click
  find("#has_eligible_health_coverage_false").click
  find(:xpath, '//*[@id="btn-continue"]').click

  find("#is_pregnant_no").click
  find("#is_post_partum_period_no").click
  find("#is_self_attested_blind_no").click
  find("#has_daily_living_no").click
  find("#need_help_paying_bills_no").click
  find("#radio_physically_disabled_no").click
  find(IvlIapOtherQuestions.continue_btn, wait: 10).click
end

Then(/^the CONTINUE button will be ENABLED$/) do
  expect(page.find('#btn-continue')[:class]).not_to include("disabled")
end

When(/^user clicks CONTINUE$/) do
  find(".btn", text: "CONTINUE").click
end

Then(/^the user will navigate to Family Relationships page$/) do
  expect(page).to have_content('Family Relationships')
end
