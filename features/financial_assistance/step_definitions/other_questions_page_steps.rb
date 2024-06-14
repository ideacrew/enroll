# frozen_string_literal: true

Given(/^all applicants fill all pages except other questions$/) do
  until find_all('.btn', text: 'ADD INCOME & COVERAGE INFO').empty?
    find_all('.btn', text: 'ADD INCOME & COVERAGE INFO')[0].click
    sleep 1
    find('#is_required_to_file_taxes_no').click
    find('#is_claimed_as_tax_dependent_no').click
    find(:xpath, "//input[@value='CONTINUE'][@name='commit']").click
    sleep 1
    find('#has_job_income_true').click
    sleep 1
    fill_in 'income[employer_name]', with: 'GloboGym'
    fill_in 'income[amount]', with: '100'
    fill_in 'income[start_on]', with: '1/1/2018'
    find_all("#job_income .incomes-list .interaction-choice-control-income-frequency-kind span.label").first.click
    find_all("#job_income li.interaction-choice-control-income-frequency-kind-7").first.click
    unless FinancialAssistanceRegistry[:disable_employer_address_fields].enabled?
      fill_in 'income[employer_address][address_1]', with: '1 K Street'
      fill_in 'income[employer_address][city]', with: 'Washington'
      fill_in 'income[employer_address][zip]', with: '20000'
      find(:xpath, '//*[@id="new_income"]/div[1]/div[4]/div[2]/div/div[2]/b').click
      find(:xpath, '//*[@id="new_income"]/div[1]/div[4]/div[2]/div/div[3]/div/ul/li[10]').click
    end
    fill_in 'income[employer_phone][full_phone_number]', with: '7898765676'
    click_button('Save')
    find('#has_self_employment_income_true').click
    fill_in 'income[amount]', with: '100.00'
    find_all("#self_employed_incomes .incomes-list .interaction-choice-control-income-frequency-kind span.label").first.click
    find_all("#self_employed_incomes li.interaction-choice-control-income-frequency-kind-7").first.click
    fill_in 'income[start_on]', with: '01/01/2018'
    click_button('Save')
    find(:xpath, '//*[@id="btn-continue"]').click

    if FinancialAssistanceRegistry[:unemployment_income].enabled?
      find('#has_unemployment_income_true').click
      sleep 1
      fill_in 'income[amount]', with: '100'
      fill_in 'income[start_on]', with: '1/1/2018'
      find(".new-unemployment-income-form .interaction-choice-control-income-frequency-kind").click
      find(".new-unemployment-income-form li.interaction-choice-control-income-frequency-kind-7").click
      click_button('Save')
    end

    find('#has_other_income_true').click
    sleep 1
    find(:css, "#other_income_kind[value='interest']").set(true)
    fill_in 'income[amount]', with: '100'
    fill_in 'income[start_on]', with: '1/1/2018'
    find(".new-other-income-form.interest span.label").click
    find(".new-other-income-form.interest li.interaction-choice-control-income-frequency-kind-7").click
    click_button('Save')
    find(:xpath, '//*[@id="btn-continue"]').click

    find('#has_deductions_true').click
    find(:css, "#deduction_kind[value='moving_expenses']").set(true)
    fill_in 'deduction[amount]', with: '50'
    fill_in 'deduction[start_on]', with: '1/1/2018'
    find(".new-deduction-form.moving_expenses span.label").click
    find(".new-deduction-form.moving_expenses li.interaction-choice-control-deduction-frequency-kind-7").click
    click_button('Save')
    find(:xpath, '//*[@id="btn-continue"]').click

    find('#has_enrolled_health_coverage_false').click
    find('#has_eligible_health_coverage_false').click

    find(:xpath, '//*[@id="btn-continue"]').click
  end
end

Given(/^the user will navigate to the FAA Household Info page$/) do
  allow(HbxProfile).to receive(:current_hbx).and_return(double(:under_open_enrollment? => false))
  visit financial_assistance.edit_application_path(application.id.to_s)
end

Given(/the No SSN Dropdown feature is disabled/) do
  allow(EnrollRegistry[:no_ssn_reason_dropdown].feature).to receive(:is_enabled).and_return(false)
  FinancialAssistanceRegistry[:no_ssn_reason_dropdown].feature.stub(:is_enabled).and_return(false)
end

Given(/the No SSN Dropdown feature is enabled/) do
  allow(EnrollRegistry[:no_ssn_reason_dropdown].feature).to receive(:is_enabled).and_return(true)
  FinancialAssistanceRegistry[:no_ssn_reason_dropdown].feature.stub(:is_enabled).and_return(true)
end

Then(/the no ssn reason dropdown is displayed/) do
  expect(page.has_css?(FinancialAssistance::OtherQuestionsPage.no_ssn_dropdown)).to eq true
end

Given(/^the user SSN is nil$/) do
  consumer.person.primary_family.family_members.each do |fm|
    fm&.person&.update_attributes(no_ssn: "1")
  end
  application&.applicants.each do |applicant|
    applicant.update_attributes(no_ssn: '1')
  end
end

Given(/^the user has an eligible immigration status$/) do
  consumer.person.consumer_role.update_attributes(citizen_status: "alien_lawfully_present")
  application.applicants.each do |applicant|
    applicant.update_attributes(citizen_status: 'alien_lawfully_present')
  end
end

Given(/^the user is a member of an indian tribe$/) do
  consumer.person.consumer_role.update_attributes(indian_tribe_member: true)
  application.applicants.each do |applicant|
    applicant.update_attributes(indian_tribe_member: true)
  end
end

Given(/^the user has an age between (\d+) and (\d+) years old$/) do |_arg1, _arg2|
  dob = TimeKeeper.date_of_record - 19.years
  consumer.person.update_attributes(dob: dob)
  application.applicants.each do |applicant|
    applicant.update_attributes(dob: dob)
  end
end

Given(/^the user has an age greater than (\d+) years old, with a young child$/) do |arg1|
  dob = TimeKeeper.date_of_record - (arg1 + rand(1..20)).year
  consumer.person.update_attributes(dob: dob)
  application.applicants.each do |applicant|
    applicant.update_attributes(dob: dob)
  end
  application.applicants.last.update_attributes(dob: (TimeKeeper.date_of_record - 3.years))
end

Then(/^the have you applied for an SSN question should display$/) do
  expect(page).to have_content('Has this person applied for an SSN?*')
end

And(/^the user answers no to the have you applied for an SSN question$/) do
  choose('is_ssn_applied_no')
end

Then(/^the reason why question is displayed$/) do
  expect(page).to have_content('Why doesn\'t this person have an SSN?')
end

Given(/^the user answers yes to being pregnant$/) do
  choose('is_pregnant_yes')
end

Then(/^the due date question should display$/) do
  expect(page).to have_content('Pregnancy due date')
end

And(/^the user enters a pregnancy due date of one month from today$/) do
  fill_in "applicant_pregnancy_due_on", with: (TimeKeeper.date_of_record + 1.month).to_s
  # Click off datepicker to close
  find('.fa-darkblue', match: :first).click
end

And(/^the user enters a pregnancy end date of one month ago$/) do
  fill_in "applicant_pregnancy_end_on", with: (TimeKeeper.date_of_record - 1.month).to_s
end

And(/^the user answers two for how many children$/) do
  find(".selectric-interaction-choice-control-children-expected-count").click
  sleep 1
  find('.interaction-choice-control-children-expected-count-2', match: :first).click
end

Given(/^the user answers yes to being a primary caregiver$/) do
  choose('is_primary_caregiver_yes')
end

Given(/^the user answers no to being a primary caregiver$/) do
  choose('is_primary_caregiver_no')
end

Then(/^the caregiver relationships should display$/) do
  expect(page).to have_content(l10n('faa.other_ques.primary_caretaker_for_text', subject: l10n("faa.other_ques.this_person")))
end

Then(/^the caregiver relationships should not display$/) do
  expect(page).to_not have_content(l10n('faa.other_ques.primary_caretaker_for_text', subject: l10n("faa.other_ques.this_person")))
end

And(/^the user selects an applicant they are the primary caregiver for$/) do
  find(:css, "#is_primary_caregiver_for").set(true)
end

Then(/^an applicant is selected as a caregivee$/) do
  expect(all(:css, "#is_primary_caregiver_for:checked").count).to be > 0
end

Then(/^the (.*?) option should display$/) do |option|
  expect(page).to have_content(option)
end

And(/^the user fills out the rest of the other questions form and submits it$/) do
  choose('is_ssn_applied_no')
  find("#has_daily_living_no").click
  find("#need_help_paying_bills_no").click
  find("#radio_physically_disabled_no").click
  choose('is_former_foster_care_no')
  choose('is_student_no')
  choose('is_self_attested_blind_no')
  choose('is_veteran_or_active_military_no')
  choose("is_primary_caregiver_no")
  choose("is_resident_post_092296_no")
  choose("medicaid_pregnancy_no") if page.all("#medicaid_pregnancy_no").present?
  find('[name=commit]').click
end

And(/^the user fills out the required other questions and submits it$/) do
  choose('is_ssn_applied_no')
  choose('is_pregnant_no')
  choose('is_post_partum_period_no')
  choose('is_former_foster_care_no')
  choose('is_student_no')
  choose('is_veteran_or_active_military_no')
  choose("is_resident_post_092296_no")
  choose("radio_physically_disabled_no")
  choose("is_primary_caregiver_no") if page.all("#is_primary_caregiver_no").present?
  choose("medicaid_pregnancy_no") if page.all("#medicaid_pregnancy_no").present?
  find('[name=commit]').click
end

And(/^the user fills out the rest of form with medicaid during pregnancy as yes and submits it$/) do
  choose('is_ssn_applied_no')
  find("#has_daily_living_no").click
  find("#need_help_paying_bills_no").click
  find("#radio_physically_disabled_no").click
  choose('is_former_foster_care_no')
  choose('is_student_no')
  choose('is_self_attested_blind_no')
  choose('is_veteran_or_active_military_no')
  choose("is_resident_post_092296_no")
  choose("medicaid_pregnancy_yes") if page.all("#medicaid_pregnancy_yes").present?
  choose("is_primary_caregiver_no") if page.all("#is_primary_caregiver_no").present?
  find('[name=commit]').click
end

And(/^the info complete applicant has an attribute is_enrolled_on_medicaid that is set to true$/) do
  last_application = FinancialAssistance::Application.last
  complete_applicant = last_application.applicants.detect { |applicant| applicant.applicant_validation_complete? }
  expect(complete_applicant.is_enrolled_on_medicaid).to eq(true)
end

Then(/^the user should see text that the info is complete$/) do
  expect(page).to have_content("Info Complete")
end


And(/^how many children question should display$/) do
  expect(page).to have_content('How many children is this person expecting?')
end

Given(/^the user answers no to being pregnant$/) do
  choose('is_pregnant_no')
end

And(/^was this person pregnant in the last (\d+) days question should display$/) do |_arg1|
  expect(page).to have_content('Was this person pregnant in the last 60 days?')
end

When(/^they answer yes to was this person pregnant in the last (\d+) days question$/) do |_arg1|
  choose('is_post_partum_period_yes')
end

Then(/^pregnancy end date question should display$/) do
  expect(page).to have_content('Pregnancy end date')
end

Then(/^the is this person a student question should display$/) do
  expect(page).to have_content(l10n('faa.other_ques.is_student', subject: l10n("faa.other_ques.this_person")))
end

Given(/^the user answers yes to being a student$/) do
  choose('is_student_yes')
end

And(/^the type of student question should display$/) do
  expect(page).to have_content('What is the type of student?')
end

And(/^student status end date question should display$/) do
  expect(page).to have_content('Student status end on date?')
end

Then(/^type of school question should display$/) do
  expect(page).to have_content('What type of school do you go to?')
end

Then(/^the has this person ever been in foster care question should display$/) do
  expect(page).to have_content('Was this person in foster care at age 18 or older?*')
end

Given(/^the user answered yes to the has this person ever been in foster care question$/) do
  choose('is_former_foster_care_yes')
end

Then(/^the where was this person in foster care question should display$/) do
  expect(page).to have_content('Where was this person in foster care?')
end

Then(/^the how old was this person when they left foster care question should display$/) do
  expect(page).to have_content('How old was this person when they left foster care?')
end

Then(/^the was this person enrolled in medicare when they left foster care should display$/) do
  expect(page).to have_content('Was this person enrolled in Medicaid when they left foster care?')
end

And(/^the user answers yes to having an eligible immigration status$/) do
  str1_markerstring = "applications/"
  str2_markerstring = "/applicants"

  application_id = page.current_path[/#{str1_markerstring}(.*?)#{str2_markerstring}/m, 1]
  str1_markerstring = "applicants/"
  str2_markerstring = "/other_questions"

  applicant_id = page.current_path[/#{str1_markerstring}(.*?)#{str2_markerstring}/m, 1]
  application = FinancialAssistance::Application.where(id: application_id).first
  current_applicant = application.applicants.find(applicant_id)
  expect(current_applicant.eligible_immigration_status).to eq(true)
end

Then(/^the did you move to the US question should display$/) do
  expect(page).to have_content('Did you move to the U.S. on or after August 22, 1996?')
end

Then(/^the military veteran question should display$/) do
  expect(page).to have_content('Are you an honorably discharged veteran or active duty member of the military?')
end

Given(/^user does not have eligible immigration status$/) do
  consumer.person.consumer_role.update_attributes(citizen_status: false)
  application.applicants.each do |applicant|
    applicant.update_attributes(eligible_immigration_status: false)
  end
end

Then(/^the military veteran question should NOT display$/) do
  expect(page).to have_content('Are you an honorably discharged veteran or active duty member of the military?')
end

Given(/^user answers no to the military veteran question$/) do
  choose('is_veteran_or_active_military_no')
end

Then(/^the are you a spouse of such a veteran question should display$/) do
  expect(page).to have_content('Are you the spouse or dependent child of such a veteran or individual in active duty status?')
end
