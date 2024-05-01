# frozen_string_literal: true

When(%r{^the user clicks ADD/EDIT INCOME & COVERAGE INFO button for a given household member$}) do
  click_link 'ADD INCOME & COVERAGE INFO'
end

Then(/^the user will navigate to the Tax Info page for the corresponding applicant\.$/) do
  expect(page).to have_content("#{l10n('family_information')}")
end

Given(/^that the user is on the Tax Info page for a given applicant$/) do
  visit financial_assistance.go_to_step_application_applicant_path(application, application.primary_applicant, 1)
end

When(/^the user clicks My Household section on the left navigation$/) do
  click_link l10n('faa.left_nav.my_household')
end

Then(/^the user will navigate to the FAA Household Info page for the corresponding application\.$/) do
  visit financial_assistance.edit_application_path(application.id.to_s)
end

When(/^the user clicks Income & Coverage section on the left navigation$/) do
  expect(page).to have_content "#{l10n('faa.left_nav.income_and_coverage_info')}"
end

Then(/^the cursor will display disabled\.$/) do
  page.html.should include('cna')
end

When(/^the user clicks Tax Info section on the left navigation$/) do
  click_link ("#{l10n('faa.left_nav.tax_info')}")
end

When(/^the user clicks Job Income section on the left navigation$/) do
  click_link  ("#{l10n('faa.left_nav.job_income')}")
end

Then(/^the user will navigate to the Job Income page for the corresponding applicant$/) do
  visit financial_assistance.edit_application_path(application.id.to_s)
end

When(/^the user clicks Other Income section on the left navigation$/) do
  click_link  ("#{l10n('faa.left_nav.other_income')}")
end

Then(/^the user will navigate to the Other Income page for the corresponding applicant\.$/) do
  visit financial_assistance.other_application_applicant_incomes_path(application, application.primary_applicant)
end

When(/^the user clicks Income Adjustments section on the left navigation$/) do
  click_link ("#{l10n('faa.left_nav.income_adjustments')}")
end

Then(/^the user will navigate to the Income Adjustments page for the corresponding applicant$/) do
  visit financial_assistance.application_applicant_deductions_path(application, application.primary_applicant)
end

When(/^the user clicks Health Coverage section on the left navigation$/) do
  click_link ("#{l10n('health_coverage')}")
end

Then(/^the user will navigate to the Health Coverage page for the corresponding applicant$/) do
  visit financial_assistance.application_applicant_benefits_path(application, application.primary_applicant)
end

When(/^the user clicks Other Questions section on the left navigation$/) do
  click_link ("#{l10n('faa.left_nav.other_questions')}")
end

Then(/^the user will navigate to the Other Questions page for the corresponding applicant$/) do
  visit financial_assistance.other_questions_application_applicant_path(application, application.primary_applicant)
  # Conditional other questions here. Checking for appearance helps!
  current_applicant_id = page.current_path.split("applicants/").last.split("/other_questions").first
  current_applicant = application.applicants.find(current_applicant_id)
  age_of_applicant = current_applicant.age_of_the_applicant
  if EnrollRegistry.feature_enabled?(:financial_assistance) && FinancialAssistanceRegistry.feature_enabled?(:primary_caregiver_other_question) &&
     age_of_applicant >= 19 && current_applicant.is_applying_coverage
    expect(page).to have_content(l10n("faa.primary_caretaker_question_text"))
  end
end