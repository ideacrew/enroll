# frozen_string_literal: true

And(/user enters applicant name, ssn, gender and dob$/) do
  fill_in FinancialAssistance::ApplicantForm.applicant_first_name, :with => 'johnson'
  fill_in FinancialAssistance::ApplicantForm.applicant_last_name, :with => 'smith'
  fill_in FinancialAssistance::ApplicantForm.applicant_form_dob, :with => '10/10/1984'
  click_outside_datepicker(l10n('family_information'))
  fill_in FinancialAssistance::ApplicantForm.applicant_form_ssn, :with => '123456543'
  find(:xpath, FinancialAssistance::ApplicantForm.applicant_form_gender_select_male).click
end

And(/user selects no for applicant's coverage requirement$/) do
  find(:xpath, FinancialAssistance::ApplicantForm.is_applying_coverage_true).click
end

And(/user selects no for applicant's incarcerated status$/) do
  choose('radio_incarcerated_no', allow_label_click: true)
end

And(/user selects no for applicant's indian_tribe_member status$/) do
  choose('indian_tribe_member_no', allow_label_click: true)
end

And(/user selects yes for applicant's us_citizen status$/) do
  choose('applicant_us_citizen_true', allow_label_click: true)
end

And(/user selects no for applicant's naturalized_citizen status$/) do
  choose('applicant_naturalized_citizen_false', allow_label_click: true)
end

And(/user clicks comfirm member$/) do
  find(".btn", text: "CONFIRM MEMBER").click
end

Then(/form should not submit due to required relationship options popup$/) do
  find(:xpath, "//div[@class='selectric-scroll']")
end

Then(/form should not submit due to required relationship error$/) do
  expect(page).to have_content "#{l10n('insured.family_members.relationship_error_message')}"
end

And(/user fills in the missing relationship$/) do
  find(:xpath, "//div[@class='selectric']").click
  find(:xpath, FinancialAssistance::ApplicantForm.applicant_spouse_select).click
end