# frozen_string_literal: true

Given(/^the user is on FAA Household Info: Family Members page$/) do
  login_as consumer, scope: :user
  step "the consumer is RIDP verified"
  hbx_profile = FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period)
  hbx_profile.benefit_sponsorship.benefit_coverage_periods.each do |bcp|
    ivl_product = FactoryBot.create(:benefit_markets_products_health_products_health_product, :ivl_product, application_period: (bcp.start_on..bcp.end_on))
    bcp.update_attributes!(slcsp_id: ivl_product.id)
  end

  visit help_paying_coverage_insured_consumer_role_index_path
  
  find(IvlIapHelpPayingForCoverage.yes_radiobtn).click
  sleep 2
  find(IvlIapApplicationChecklist.continue_btn).click
  sleep 2
  find(IvlIapApplicationChecklist.continue_btn).click

  # should be on application year select page
  # TODO: Will need to be updated when year select logic implemented
  if EnrollRegistry.feature_enabled?(:iap_year_selection)
    if EnrollRegistry[:bs4_consumer_flow].enabled?
      find(IvlIapApplicationChecklist.begin_application_btn).click
    else
    find('.interaction-click-control-continue').click
    sleep 2
    end
  end

  # should be on checklist page now
end

And(/^the user visits the portal outside OE$/) do
  hbx_profile = FactoryBot.create(:hbx_profile, :no_open_enrollment_coverage_period)
  hbx_profile.benefit_sponsorship.benefit_coverage_periods.each do |bcp|
    ivl_product = FactoryBot.create(:benefit_markets_products_health_products_health_product, :ivl_product, application_period: (bcp.start_on..bcp.end_on))
    bcp.update_attributes!(slcsp_id: ivl_product.id)
  end
end

And(/^the user visits the portal during OE$/) do
  hbx_profile = FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period)
  hbx_profile.benefit_sponsorship.benefit_coverage_periods.each do |bcp|
    ivl_product = FactoryBot.create(:benefit_markets_products_health_products_health_product, :ivl_product, application_period: (bcp.start_on..bcp.end_on))
    bcp.update_attributes!(slcsp_id: ivl_product.id)
  end
end

And(/^the user is on the FAA Household Info page$/) do
  login_as consumer, scope: :user
  visit help_paying_coverage_insured_consumer_role_index_path
  find('button.interaction-click-control-continue')
  choose('radio1', allow_label_click: true)
  find('button.interaction-click-control-continue').click

  person = Person.all.last
  person.user.update_attributes(identity_response_code: "acc", identity_final_decision_code: "acc")
  # should be on application year select page
  # TODO: Will need to be updated when year select logic implemented
  if EnrollRegistry.feature_enabled?(:iap_year_selection)
    find('a.interaction-click-control-continue').click
    sleep 2
  end
  # should be on checklist page now
  #find('a.interaction-click-control-continue').click

end

Given(/^all applicants are in Info Completed state%/) do
  until find_all('.btn', text: 'ADD INCOME & COVERAGE INFO').empty?
    find_all('.btn', text: 'ADD INCOME & COVERAGE INFO')[0].click
    choose(IvlIapTaxInformationPage.file_taxes_no_radiobtn, wait: 5)
    choose(IvlIapTaxInformationPage.claimed_as_tax_dependent_no_radiobtn)
    find(IvlIapTaxInformationPage.continue_btn).click
    choose(IvlIapJobIncomeInformationPage.has_job_income_no_radiobtn)
    find(IvlIapJobIncomeInformationPage.continue_btn).click

    choose(IvlIapOtherIncomePage.has_unemployment_income_no_radiobtn)
    choose(IvlIapOtherIncomePage.has_other_income_no_radiobtn)
    find(IvlIapOtherIncomePage.continue_btn).click

    choose(IvlIapIncomeAdjustmentsPage.income_adjustments_no_radiobtn)
    find(IvlIapIncomeAdjustmentsPage.continue_btn).click

    choose(IvlIapHealthCoveragePage.has_enrolled_health_coverage_no_radiobtn)
    choose(IvlIapHealthCoveragePage.has_eligible_health_coverage_no_radiobtn)
    find(IvlIapHealthCoveragePage.continue).click
    choose(IvlIapOtherQuestions.is_pregnant_no_radiobtn)
    choose(IvlIapOtherQuestions.is_post_partum_period_no_radiobtn)
    choose(IvlIapOtherQuestions.person_blind_no_radiobtn)
    choose(IvlIapOtherQuestions.has_daily_living_help_no_radiobtn)
    choose(IvlIapOtherQuestions.need_help_paying_bills_no_radiobtn)
    choose(IvlIapOtherQuestions.physically_disabled_no_radiobtn)
    find(IvlIapOtherQuestions.continue_btn).click
  end
end

Given(/^all applicants are in Info Completed state with all types of income$/) do
  until find_all('.btn', text: 'ADD INCOME & COVERAGE INFO').empty?
    find_all('.btn', text: 'ADD INCOME & COVERAGE INFO')[0].click
    find(IvlIapTaxInformationPage.file_taxes_no_radiobtn).click
    find(IvlIapTaxInformationPage.claimed_as_tax_dependent_no_radiobtn).click
    find(IvlIapTaxInformationPage.continue_btn).click
    find(IvlIapJobIncomeInformationPage.has_job_income_yes_radiobtn).click
    sleep 1
    fill_in IvlIapJobIncomeInformationPage.employer_name, with: 'GloboGym'
    fill_in IvlIapJobIncomeInformationPage.income_amount, with: '100'
    fill_in IvlIapJobIncomeInformationPage.income_from, with: '1/1/2018'
    find(IvlIapJobIncomeInformationPage.income_how_often_dropdown).click
    find(IvlIapJobIncomeInformationPage.select_yearly).click
    sleep 5
    fill_in IvlIapJobIncomeInformationPage.income_employer_address_1, with: '1 K Street'
    fill_in IvlIapJobIncomeInformationPage.income_employer_city, with: 'Washington'
    fill_in IvlIapJobIncomeInformationPage.income_employer_zip, with: '20000'
    find(IvlIapJobIncomeInformationPage.income_employer_state_dropdown).click
    find(IvlIapJobIncomeInformationPage.select_dc).click
    fill_in IvlIapJobIncomeInformationPage.income_employer_phone_number, with: '7898765676'
    find(IvlIapJobIncomeInformationPage.income_save_btn).click
    find(IvlIapJobIncomeInformationPage.has_self_employee_income_yes_radiobtn).click
    
    fill_in IvlIapJobIncomeInformationPage.self_employee_income_amount, with: '100.00'
    find(IvlIapJobIncomeInformationPage.self_employee_how_often_dropdown).click
    find(IvlIapJobIncomeInformationPage.self_employed_yearly).click
    fill_in IvlIapJobIncomeInformationPage.self_employee_income_from, with: '01/01/2018'
    find(IvlIapJobIncomeInformationPage.self_self_employee_save_btn).click
    find(IvlIapJobIncomeInformationPage.continue_btn).click

    if FinancialAssistanceRegistry[:unemployment_income].enabled?
      find(IvlIapOtherIncomePage.has_unemployment_income_yes_radiobtn).click
      sleep 1
      fill_in IvlIapOtherIncomePage.income_amount, with: '100'
      fill_in IvlIapOtherIncomePage.income_from, with: '1/1/2018'
      find(IvlIapOtherIncomePage.how_often_dropdown).click
      find(IvlIapOtherIncomePage.select_yearly).click
      find(IvlIapOtherIncomePage.unemployment_save_btn).click
    end
    find(IvlIapOtherIncomePage.has_other_income_yes_radiobtn).click
    sleep 1
    find('.other-income-checkbox-interest.interaction-choice-control-value-other-income-kind').click
  
    fill_in IvlIapOtherIncomePage.income_amount, with: '100'
    fill_in IvlIapOtherIncomePage.income_from, with: '1/1/2018'
    
    find(IvlIapOtherIncomePage.interest_how_often_dropdown).click
    find(IvlIapOtherIncomePage.interest_select_yearly).click

    within('.new-other-income-form.interest') do
      find(IvlIapOtherIncomePage.has_other_income_save_btn).click
    end

    find(IvlIapOtherIncomePage.continue_btn).click
    find(IvlIapIncomeAdjustmentsPage.income_adjustments_yes_radiobtn).click
    find(:css, "#deduction_kind[value='moving_expenses']").set(true)
    fill_in IvlIapIncomeAdjustmentsPage.amount, with: '50'
    fill_in IvlIapIncomeAdjustmentsPage.from, with: '1/1/2018'
    find(IvlIapIncomeAdjustmentsPage.moving_expenses_how_often_dropdown).click
    find(IvlIapIncomeAdjustmentsPage.moving_expenses_select_yearly).click

    within('.new-deduction-form.moving_expenses') do
      find(IvlIapIncomeAdjustmentsPage.income_adjustments_save_btn).click
    end

    find(IvlIapIncomeAdjustmentsPage.continue_btn).click
    find(IvlIapHealthCoveragePage.has_enrolled_health_coverage_no_radiobtn).click
    find(IvlIapHealthCoveragePage.has_eligible_health_coverage_no_radiobtn).click
    find(IvlIapHealthCoveragePage.continue).click
    find(IvlIapOtherQuestions.is_pregnant_no_radiobtn).click
    find(IvlIapOtherQuestions.is_post_partum_period_no_radiobtn).click
    find(IvlIapOtherQuestions.person_blind_no_radiobtn).click
    find(IvlIapOtherQuestions.has_daily_living_help_no_radiobtn).click
    find(IvlIapOtherQuestions.need_help_paying_bills_no_radiobtn).click
    find(IvlIapOtherQuestions.physically_disabled_no_radiobtn).click
    find(IvlIapOtherQuestions.continue_btn).click
  end
end

Then(/the user is on the Family Information page with missing applicant income amount/) do
  find_all(IvlIapApplicationChecklist.previous_link).first.click
  FinancialAssistance::Application.first.applicants.first.incomes.first.update_attributes!(amount: nil, frequency_kind: 'biweekly')
end

Then(/the user should see a missing applicant info error message/) do
  expect(find_all('.alert').first[:class].include?('alert-error')).to be true
end

Then(/^the user is on the Submit Your Application page$/) do
  expect(page).to have_content('Submit Your Application')
end

Then(/^the Parent Living Outside Home Attestation Checkbox is present$/) do
  find('#living_outside_yes').click
  expect(page).to have_css("#application_attestation_terms")
end

Given(/^a required question is not answered$/) do
  expect(find("#application_medicaid_terms").checked?).to be(false)
end

Given(/^the user has not signed their name$/) do
  expect(find('#first_name_thank_you').text.empty?).to eq(true)
  expect(find('#last_name_thank_you').text.empty?).to eq(true)
end

Then(/^the submit button will be disabled$/) do
  expect(find('.interaction-click-control-submit-application')[:class].include?('disabled')).to be(true)
end

Given(/^all required questions are answered$/) do
  # getting and looping through each checkbox id looks unnecessary but using find_all directly does not work as expected
  check_box_ids = find_all("input[type='checkbox']").map { |checkbox| checkbox[:id] }
  check_box_ids.each { |id| find("##{id}").check }
  # sets radio button to no
  find('#living_outside_no').set(true)
  find('#medicaid_determination_no').set(true)
end

And(/^the user should be able to see medicaid determination question$/) do
  if FinancialAssistanceRegistry.feature_enabled?(:full_medicaid_determination_step)
    expect(page).to have_content("full review of your application for Medicaid eligibility?")
    find('#medicaid_determination_yes').click
  end
end

Given(/^the user has signed their name$/) do
  fill_in IvlConfirmYourPlanSelection.first_name, with: application.primary_applicant.first_name
  fill_in IvlConfirmYourPlanSelection.last_name, with: application.primary_applicant.last_name
  # Remove focus from the last name field by clicking on header text
  find('.fa-darkblue').click
end

Then(/^the submit button will be enabled$/) do
  expect(find('.interaction-click-control-submit-application')[:class].include?('disabled')).to be(false)
end

Then(/^the user is on the Error Submitting Application page$/) do
  expect(page).to have_content('Submission Error:')
  expect(page).to have_content('Error Submitting Application')
end

Then(/^the user is on the Eligibility Response page$/) do
  expect(page).to have_content('Eligibility Response Error', wait: 60)
end

Given(/^the user clicks SUBMIT$/) do
  find('.interaction-click-control-submit-application').click
end

And(/^the user waits for eligibility results$/) do
  sleep 20
end

Then(/^the user should land on sep page$/) do
  expect(page).to have_content('Special Enrollment Period')
end

Then(/^the user should land on Coverage Household page$/) do
  expect(page).to have_content('Choose Coverage for your Household')
end
