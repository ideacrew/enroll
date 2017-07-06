Given(/^a consumer, with a family, exists$/) do
  consumer :with_nuclear_family
end

Given(/^is logged in$/) do
  login_as consumer, scope: :user
end

When /^the consumer views their applications$/ do
  visit financial_assistance_applications_path
end

When(/^they click 'New Financial Assistance Application' button$/) do
  click_button "Start new application"
end

Then(/^they should see a new finanical assistance application$/) do
# Identifying this by the id being on the page, getting id from the url
  id = page.current_url[/applications\/(.*)\/edit/, 1]
  expect(page).to have_content("ID # #{id}")
end

Then(/^they should see each of their dependents listed$/) do
  consumer.person.families.last.family_members.each do |family_member|
    expect(page).to have_content(family_member.first_name)
  end
end

Given(/^the consumer has started a financial assistance application$/) do
  application
end

When(/^they view the financial assistance application$/) do
  visit edit_financial_assistance_application_path(application)
end

Then(/^they should be taken back to the application's details page for applicant$/) do
  page.should have_content('Applicant deleted.')
end

When(/^they click edit for an applicant$/) do
  click_link 'Add Info'
end

When(/^they complete and submit the tax information$/) do
  choose("is_required_to_file_taxes_yes")
  choose("is_claimed_as_tax_dependent_yes")
  find('#applicant_claimed_as_tax_dependent_by').select(consumer.person.full_name)
  click_button 'Next step'
  choose("is_ssn_applied_yes")
  choose("is_pregnant_yes")
  fill_in 'applicant_pregnancy_due_on', with: "11/11/2016"
  find('.selectric-interaction-choice-control-applicant-children-expected-count').click
  page.all('.interaction-choice-control-applicant-children-expected-count-3')[1].click
  choose("is_post_partum_period_yes")
  fill_in 'applicant_pregnancy_end_on', with: "11/11/2017"
  choose("medicaid_pregnency_yes")
  choose("is_student_yes")
  find('.selectric-interaction-choice-control-applicant-student-kind').click
  page.all('.interaction-choice-control-applicant-children-expected-count-3')[1].click
  find('.selectric-interaction-choice-control-applicant-student-school-kind').click
  page.all('.interaction-choice-control-applicant-children-expected-count-3')[1].click
  fill_in 'applicant_student_status_end_on', with: "12/15/2017"
  find("#is_self_attested_blind_yes").trigger('click')
  find("#has_daily_living_help_yes").trigger('click')
  find("#need_help_paying_bills_yes").trigger('click')
  click_button 'Finish'
end

Then(/^they should be taken to the applicant's details page$/) do
  visit edit_financial_assistance_application_applicant_path(application, application.primary_applicant)
end

Then(/^see some of the tax information on the applicant's detail page$/) do
  expect(page).to have_content(application.primary_applicant.family_member.person.full_name)
  expect(page).to have_content(application.primary_applicant.is_claimed_as_tax_dependent)
  expect(page).to have_content(application.primary_applicant.claimed_as_tax_dependent_by)
end

Given(/^has added tax information for an applicant$/) do
# right now this step is unnecessary but not always be
end

When(/^they view the applicant's details page$/) do
  visit edit_financial_assistance_application_applicant_path(application, application.primary_applicant)
end

And(/^they click on the 'Add Income' button$/) do
  click_link 'Add Income'
end

And(/^they complete the form for the income$/) do
  find('#income_yes').click
  fill_in 'income[amount]', with: '23.3'
  find_all(".interaction-choice-control-employer-address-state")[1].click
  find_all(".interaction-choice-control-income-frequency-kind-1")[1].click
  fill_in 'income[start_on]', with: "11/11/2016"
  fill_in 'income[end_on]', with: "11/11/2017"
  fill_in 'income[employer_name]', with: "Sample Employer 1"
  fill_in 'employer_phone[full_phone_number]', with: "2036548484"
  fill_in 'employer_address[address_1]', with: "12 main st"
  fill_in 'employer_address[address_2]', with: "beside starbucks"
  fill_in 'employer_address[city]', with: "washington"
  find('#employer_address_state').select('DC')
  fill_in 'employer_address[zip]', with: "22046"
  # click_button 'Finish'
  page.find(".interaction-click-control-finish").trigger('click')
end

And(/^they click on 'Remove Income' button$/) do
  click_on 'Delete'
  page.accept_alert
end

And(/^they should see the newly added income/) do
  page.should have_content('Income Added')
end


Then(/^they should be taken back to the application's details page for income$/) do
page.should have_content('Income deleted')
end

Then(/^the income should be no longer be shown$/) do
# pending # Write code here that turns the phrase above into concrete actions
end
#Starting here .........

# Given(/^has added an benefit$/) do
#   click_button 'Add Benefit'
#   choose("yes2")
#   find_all(".interaction-choice-control-benefit-kind-4")[1].click
#   fill_in 'benefit[start_on]', with: "11/11/2016"
#   fill_in 'benefit[end_on]', with: "11/11/2017"
#   click_button 'Next step'
#   choose("yes2")
#   fill_in 'benefit[employer_name]', with: "JOHN"
#   fill_in 'employer_address[address_1]', with: " Test address 1"
#   fill_in 'employer_address[city]', with: " Herdon"
#   fill_in 'employer_address[zip]', with: " 51023"
#   choose("yes2")
#   choose("yes2")
#   fill_in 'benefit[employee_cost]', with: " 2.3"
#   click_button 'Finish'
# end


# When(/^they click on 'Remove Benefit' button$/) do
#   pending # Write code here that turns the phrase above into concrete actions
# end

Then(/^the benefit should be no longer be shown$/) do
pending # Write code here that turns the phrase above into concrete actions
end

Given(/^has added an deduction$/) do
pending # Write code here that turns the phrase above into concrete actions
end

Then(/^the deduction should be no longer be shown$/) do
pending # Write code here that turns the phrase above into concrete actions
end
#Last step
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>

Given(/^the consumer has completed a financial assistance application$/) do
  visit edit_financial_assistance_application_path(application)
end

When(/^they view the financial assistance application for review$/) do
  visit edit_financial_assistance_application_path(application)
end

And (/^click the 'Review and Continue' button$/) do
  click_button "Review and Continue"
end

And (/^they review and submit the application$/) do
  choose("eligibility_easier_yes")
  choose("mailed_yes")
  click_button 'Next step'
  check("application_medicaid_terms")
  check("application_report_change_terms")
  check("application_medicaid_insurance_collection_terms")
  choose("living_outside_yes")
  check("application_attestation_terms")
  check("application_submission_terms")
  page.find(".interaction-click-control-submit-my-application").trigger('click')
end


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
When(/^click the "([^"]*)" button$/) do |arg1|
pending # Write code here that turns the phrase above into concrete actions
end

Then(/^they are taken back to view all applications$/) do
  visit financial_assistance_applications_path
end

Then(/^they will see that their application has been submitted$/) do
  page.find(".interaction-click-control-start-new-application")
end

When(/^they click on the 'Add deduction' button$/) do
  click_link 'Add Deduction'
end


Given (/^the consumer has started a financial assistance application1$/) do
  visit edit_financial_assistance_application_applicant_path(application, application.primary_applicant)
end
When (/^they click on 'Add Benefit' button$/) do
  click_link 'Add Benefit'
end

# And (/^has added an benefit$/) do
#   choose("yes2")
#   find('#benefit_kind').select('medicare')
#   fill_in 'benefit[start_on]', with: "11/11/2016"
#   fill_in 'benefit[end_on]', with: "11/11/2017"
#   click_button 'Next step'
#   choose("access_to_hc_yes")
#   fill_in 'benefit[employer_name]', with: "JOHN"
#   fill_in 'employer_address[address_1]', with: " Test address 1"
#   fill_in 'employer_address[city]', with: " Herdon"
#   fill_in 'employer_address[zip]', with: " 51023"
#   choose("is_eligible_no")
#   choose("health_plan_yes")
#   fill_in 'benefit[employee_cost]', with: " 2.3"
# end

And (/^they complete the form for the benefit$/) do
  find('#is_eligible').click
  find('#benefit_insurance_kind').select('Acf Refugee Medical Assistance')
  click_button 'Finish'
end

Then(/^they should be taken back to the applicant's detail page$/) do

end
And (/^they should see the newly added benefit$/) do
  page.should have_content('Benefit Info Added.')
end

# When (/^they view the applicant's details page$/) do
#   page.should have_content('Edit Applicant')
# end

Then (/^they click on 'Remove Benefit' button/) do
  click_on 'Delete'
  page.accept_alert
end

And (/^they should be taken back to the application's details page for benefit$/) do
page.should have_content('Benefit deleted')
end

## Remove Deduction

When (/^they click on 'Add Deduction' button$/) do
  click_link 'Add Deductions'
end

And (/^they complete the form for the deduction/) do
  choose("adjustments_yes")
  find('#deduction_kind').select('Alimony Paid')
  find('#deduction_frequency_kind').select('quarterly')
  fill_in 'deduction[amount]', with: "2.2"
  # find_all(".interaction-choice-control-deduction-frequency-kind")[2].click
  fill_in 'deduction[start_on]', with: "10/11/2016"
  fill_in 'deduction[end_on]', with: "11/18/2016"
  click_button 'Finish'
end

And (/^they should see the newly added deduction$/) do
  page.should have_content('Deduction Added')
end

Then (/^they click on 'Remove deduction' button/) do
  page.find('.interaction-click-control-delete').click
  page.accept_alert
end

And (/^they should be taken back to the application's details page for deduction$/) do
  page.should have_content('Deduction deleted')
end
