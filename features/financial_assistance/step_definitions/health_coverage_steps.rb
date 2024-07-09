# frozen_string_literal: true

Then(/^they should be taken to the applicant's Tax Info page \(health coverage\)$/) do
  sleep 5
  expect(page).to have_selector("[data-cuke='tax_info_header']")
end

Then(/^they visit the Health Coverage page via the left nav \(also confirm they are on the Health Coverage page\)$/) do
  visit financial_assistance.application_applicant_benefits_path(application.id, application.primary_applicant.id)
  expect(find("#health-coverage-page")).to_not be(nil)
end

Given(/^the user answers no to currently having health coverage$/) do
  choose('has_enrolled_health_coverage_false')
end

Then(/^the health coverage choices should not show$/) do
  expect(page).not_to have_xpath("//*[@id='enrolled-benefit-kinds']")
end

Given(/^the user answers yes to currently having health coverage$/) do
  choose('has_enrolled_health_coverage_true')
end

Then(/^the health coverage choices should show$/) do
  expect(page).to have_xpath("//*[@id='enrolled-benefit-kinds']")
end

Given(/^the user answers no to currently having access to other health coverage$/) do
  choose('has_eligible_health_coverage_false')
end

Then(/^the other health coverage choices should not show$/) do
  expect(page).not_to have_xpath("//*[@id='eligible-benefit-kinds']")
end

Given(/^the user answers yes to currently having access to other health coverage$/) do
  find(IvlIapHealthCoveragePage.has_eligible_health_coverage_yes_radiobtn).click
end

Then(/^the other health coverage choices should show$/) do
  expect(page).to have_xpath("//*[@id='eligible-benefit-kinds']")
end

Given(/^the user checks a health coverage checkbox$/) do
  skip_this_scenario unless ::FinancialAssistanceRegistry.feature_enabled?(:acf_refugee_medical_assistance)
  find(:css, "#insurance_kind[value='acf_refugee_medical_assistance']").set(true)
end

Given(/^the user checks a hra checkbox$/) do
  skip_this_scenario unless ::FinancialAssistanceRegistry.feature_enabled?(:health_reimbursement_arrangement)

  find(:css, "#insurance_kind[value='health_reimbursement_arrangement']").set(true)
end

And(/^the user checks a employer sponsored health coverage checkbox$/) do
  find(:css, "#insurance_kind[value='employer_sponsored_insurance']").set(true)
end

Then(/^the health plan meets mvs and affordable question should show$/) do
  expect(page).to have_content(l10n('health_plan_meets_mvs_and_affordable_question')&.to_s)
end

Then(/^the employer id field should indicate it is required$/) do
  expect(find("#benefit_esi_ein")["placeholder"]).to include "*"
end

Then(/^the employer id label should indicate it is required$/) do
  expect(find(CostSavingsApplicationPage.benefit_esi_ein_label).text).to include "*"
end

And(/^the user not sure link next to minimum standard value question$/) do
  find("#is_esi_mec_met_not_sure").click
end

Then(/^the user should be see proper text in the modal popup$/) do
  expect(page).to have_content('The minimum value is a standard used to see if a health plan offered by your employer meets the basic requirements of the Affordable Care Act.')
end

Then(/^the medicare have glossary link$/) do
  expect(page.has_css?(IvlIapHealthCoveragePage.medicare)).to be_truthy
  expect(page.has_css?(IvlIapHealthCoveragePage.medicare_glossary_link)).to be_truthy
end

Then(/^the medicare have glossary content$/) do
  #bug logged for this, glossary text issue on health coverage page for medicare,medicaid, coverage and cobra
  find(IvlIapHealthCoveragePage.medicare_glossary_link).click
  expect(page).to have_content "The program helps with the cost of health care, but it doesn't cover all medical expenses or the cost of most"
end

Then(/^the coverage_obtained_through_another_exchange does not have glossary link$/) do
  expect(page.has_css?(IvlIapHealthCoveragePage.coverage_obtained_through_another_exchange)).to be_truthy
  expect(page.has_css?(IvlIapHealthCoveragePage.coverage_obtained_through_another_exchange_glossary_link)).to be_falsy
end

Then(/^the health coverage form should show$/) do
  expect(page).to have_xpath("//*[@id='acf_refugee_medical_assistance']/div[2]/div")
end

Then(/^the other health coverage form should show$/) do
  expect(page).to have_xpath("//*[@id='acf_refugee_medical_assistance']/div[2]")
end

Then(/^the esi question should be about your job rather than a job$/) do
  expect(page).to have_content('Coverage through your job (also known as employer-sponsored health insurance)')
end

And(/^the user checks on job coverage checkbox$/) do
  find(:css, CostSavingsApplicationPage.employer_sponsored_insurance_benefit_checkbox).set(true)
end

Given(/the FAA short_enrolled_esi_forms feature is enabled/) do
  enable_feature :short_enrolled_esi_forms, {registry_name: FinancialAssistanceRegistry}
  enable_feature :short_enrolled_esi_forms
end

Then(/^the user should see the esi form$/) do
  expect(page.has_css?(CostSavingsApplicationPage.esi_benefit)).to eq true
end

Then(/^the user should see the non_esi form$/) do
  expect(page.has_css?(CostSavingsApplicationPage.non_esi_benefit)).to eq true
end

Given(/^the user fills out the required health coverage information$/) do
  fill_in 'benefit[start_on]', with: "02/01/2018"
end

And(/^the user fills out the required hra form$/) do
  fill_in 'benefit_employer_name', with: "Test Employer"
  fill_in 'benefit_employer_address_address_1', with: "Address line1"
  fill_in 'benefit_employer_address_city', with: "Test"
  page.find('.selectric-interaction-choice-control-benefit-employer-address-state').click
  page.all('li').detect { |li| li.text == "DC" }.click
  fill_in 'benefit_employer_address_zip', with: "28102"
  fill_in 'benefit_employer_phone_full_phone_number', with: "2810229201"
  fill_in 'benefit_employer_id', with: "382918294"
  page.find('.selectric-interaction-choice-control-benefit-hra-type').click
  page.all('li').detect { |li| li.text == "Individual coverage HRA" }.click
  fill_in 'benefit_employer_id', with: "382918294"
  fill_in 'benefit[start_on]', with: "02/01/2018"
  fill_in 'benefit_employee_cost', with: "2000"
  page.find('.selectric-interaction-choice-control-benefit-employee-cost-frequency').click
  page.all('li').detect { |li| li.text == "Weekly" }.click
end

Then(/^the user saves the health coverage information$/) do
  click_button 'Save'
end

Then(/^the health coverage should be saved on the page$/) do
  expect(page).to have_content '02/01/2018'
end

Then(/^the hra health coverage should be saved on the page$/) do
  expect(page).to have_content 'Type of HRA'
  expect(page).to have_content 'Individual coverage HRA'
end

Then(/^the health coverage checkbox should be unchecked$/) do
  expect(find(:css, "#insurance_kind[value='acf_refugee_medical_assistance']")).not_to be_checked
end

Then(/^the health coverage form should not show$/) do
  expect(page).to_not have_content '02/01/2018'
end

Then(/they should see the Indian Healthcare Eligible question/) do
  expect(page).to have_content l10n("faa.indian_health_service_eligible")
end

Then(/they should see the Indian Healthcare question/) do
  expect(page).to have_content l10n("faa.indian_health_service")
end

Then(/they should see the MaineCare ineligible question/) do
  expect(page).to have_content(IvlIapHealthCoveragePage.mainecare_ineligible_question_text)
end

Then(/they clicks yes for MaineCare ineligible/) do
  find('#medicaid_chip_ineligible_true').click
end

Then(/they should see the immigration status question/) do
  expect(page).to have_content l10n("faa.immigration_status_changed")
end

And(/the user checks on not sure link for hra checkbox/) do
  find(:xpath, "/html/body/div[3]/div[2]/div/div[2]/div[1]/div[2]/div[2]/div[3]/a").click
end

Then(/should see not sure modal pop up/) do
  find('#has_enrolled_health_coverage_from_hra') if FinancialAssistanceRegistry[:has_enrolled_health_coverage].setting(:currently_enrolled_with_hra).item
  find('#has_enrolled_health_coverage') if FinancialAssistanceRegistry[:has_enrolled_health_coverage].setting(:currently_enrolled).item
end
