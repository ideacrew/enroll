# frozen_string_literal: true

Given(/^a consumer, with a family, exists$/) do
  consumer :with_nuclear_family
  bcp = FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period).benefit_sponsorship.current_benefit_coverage_period
  ivl_product = FactoryBot.create(:benefit_markets_products_health_products_health_product, :ivl_product, application_period: (bcp.start_on..bcp.end_on))
  bcp.update_attributes!(slcsp_id: ivl_product.id)
end

Given(/^is logged in$/) do
  login_as consumer, scope: :user
end

Given(/^a benchmark plan exists$/) do
  create_plan
end

When(/^the consumer views their applications$/) do
  visit financial_assistance.applications_path
end

When(/^a consumer visits the Get Help Paying for coverage page$/) do
  visit help_paying_coverage_insured_consumer_role_index_path
end

When(/^selects yes they would like help paying for coverage$/) do
  find('button.interaction-click-control-continue')
  choose('radio1', allow_label_click: true)
  find('button.interaction-click-control-continue').click

  # should be on checklist page now
  find('a.interaction-click-control-continue').click
end

When(/^they click 'Start New Application' button$/) do
  click_button 'Start new application'
end

Then(/^they should see a new finanical assistance application$/) do
  expect(page.current_url).to match("/applications/.*/edit")
end

Then(/^they should see each of their dependents listed$/) do
  consumer.person.primary_family.family_members.each do |family_member|
    expect(page).to have_content(family_member.first_name)
  end
end

Given(/^the consumer has started a financial assistance application$/) do
  application
end

When(/^they view the financial assistance application$/) do
  visit financial_assistance.edit_application_path(application)
end

When(/^they click ADD INCOME & COVERAGE INFO for an applicant$/) do
  click_link 'ADD INCOME & COVERAGE INFO', href: financial_assistance.go_to_step_application_applicant_path(application_id: application.id, id: application.primary_applicant.id, step: 1)
end

Then(/^they should be taken to the applicant's Tax Info page$/) do
  expect(page).to have_content("Tax Info for #{consumer.person.first_name}")
end

And(/^they visit the applicant's Job income page$/) do
  visit financial_assistance.application_applicant_incomes_path(application, application.primary_applicant)
end

And(/^they answer job income question and complete the form for the Job income$/) do
  choose('has_job_income_true')
  sleep 1
  fill_in 'income[employer_name]', with: "Sample Employer"
  fill_in 'income[amount]', with: '23.3'
  find_all(".interaction-choice-control-income-frequency-kind")[1].click
  find_all('.interaction-choice-control-income-frequency-kind-7')[0].click
  fill_in 'income[start_on]', with: "11/11/2016"
  fill_in 'income[end_on]', with: "11/11/2017"
  # TODO: This isn't showing up
  # page.find('.darkblue').click
  fill_in 'income[employer_phone][full_phone_number]', with: "2036548484"
  fill_in 'income[employer_address][address_1]', with: "12 main st"
  fill_in 'income[employer_address][address_2]', with: "beside starbucks"
  fill_in 'income[employer_address][city]', with: "washington"
  find_all(".interaction-choice-control-income-employer-address-state")[0].click
  find_all(".interaction-choice-control-income-employer-address-state-5")[0].click
  fill_in 'income[employer_address][zip]', with: "22046"
  click_button 'Save'
end

Given(/^they answer job income question and complete the form with incorrect data format$/) do
  choose('has_job_income_true')
  sleep 1
  fill_in 'income[employer_name]', with: "Sample Employer"
  fill_in 'income[amount]', with: '23.3'
  find_all(".interaction-choice-control-income-frequency-kind")[1].click
  find_all('.interaction-choice-control-income-frequency-kind-7')[0].click
  fill_in 'income[start_on]', with: "11/11/16"
  find_all(".interaction-choice-control-income-employer-address-state")[0].click
  # TODO: This isn't showing up
  # page.find('.darkblue').click
end

Then(/^I should see a JS alert$/) do
  page.accept_alert
end

Then(/^they should see the newly added Job income$/) do
  page.should have_content('Sample Employer')
end

Then(/^they should see the dates in correct format$/) do
  page.should have_content('11/11/2016')
  page.should have_content('11/11/2017')
end

Then(/^they should be taken back to the application's details page for applicant$/) do
  page.should have_content('Applicant deleted.')
end

When(/^they click edit for an applicant$/) do
  click_link 'Add Info', href: "/financial_assistance/applications/#{application.id}/applicants/#{application.primary_applicant.id}/step/1"
end

When(/^they complete and submit the Income and Coverage information$/) do
  choose("income_from_employer_yes")
  choose("self_employed_no")
  choose("other_income_no")
  choose("adjustments_income_no")
  choose("enrolled_in_coverage_no")
  choose("access_to_other_coverage_no")

  click_button 'CONTINUE'
end


Given(/^has added tax information for an applicant$/) do
  # right now this step is unnecessary but not always be
end

Given(/^they visit the applicant's Income page$/) do
  visit financial_assistance.application_applicant_incomes_path(application, application.primary_applicant)
end

Given(/^they visit the applicant's Benefits page$/) do
  visit financial_assistance.application_applicant_benefits_path(application, application.primary_applicant)
end

Given(/^they visit the applicant's Deductions page$/) do
  visit financial_assistance.application_applicant_deductions_path(application, application.primary_applicant)
end

And(/^they click on the 'Add Income' button$/) do
  click_link 'Add Income'
end

And(/^they complete the form for the income$/) do
  fill_in 'income[amount]', with: '23.3'
  find_all(".interaction-choice-control-financial-assistance-income-employer-address-state")[0].trigger('click')
  find_all(".interaction-choice-control-financial-assistance-income-employer-address-state").select('Monthly')
  fill_in 'income[start_on]', with: "11/11/2016"
  fill_in 'income[end_on]', with: "11/11/2017"
  fill_in 'income[employer_name]', with: "Sample Employer 1"
  fill_in 'employer_phone[full_phone_number]', with: "2036548484"
  fill_in 'employer_address[address_1]', with: "12 main st"
  fill_in 'employer_address[address_2]', with: "beside starbucks"
  fill_in 'employer_address[city]', with: "washington"
  find('#employer_address_state').select('DC')
  fill_in 'employer_address[zip]', with: "22046"

  click_button 'CONTINUE'
end

And(/^they click on 'Remove Income' button$/) do
  find(:xpath, '//a[@data-method="delete"][span]').click
  page.accept_alert
end

And(/^they should see the newly added income/) do
  page.should have_content('Income Added')
end


Then(/^they should be taken back to the application's details page for income$/) do
  page.should have_content("Income for #{application.primary_applicant.first_name}")
end

Then(/^the income should be no longer be shown$/) do
  page.should have_content('Income deleted')
end

Then(/^the benefit should be no longer be shown$/) do
  page.should have_content('Benefit deleted')
end

Then(/^the deduction should be no longer be shown$/) do
  page.should have_content('Deduction deleted')
end

Given(/^the consumer has completed a financial assistance application$/) do
  # Kelly to John
  application.active_applicants.second.person.person_relationships.create(
    {
      kind: 'spouse',
      family_id: consumer.primary_family.id,
      successor_id: application.active_applicants.first.person.id,
      predecessor_id: application.active_applicants.second.person.id
    }
  )
  # Danny to John
  application.active_applicants.third.person.person_relationships.create(
    {
      kind: 'parent',
      family_id: consumer.primary_family.id,
      successor_id: application.active_applicants.first.person.id,
      predecessor_id: application.active_applicants.third.person.id
    }
  )
  # Danny to Kelly
  application.active_applicants.third.person.person_relationships.create(
    {
      kind: 'parent',
      family_id: consumer.primary_family.id,
      successor_id: application.active_applicants.second.person.id,
      predecessor_id: application.active_applicants.third.person.id
    }
  )
  application.active_applicants.each do |applicant|
    applicant.update_attributes(
      is_required_to_file_taxes: false,
      is_claimed_as_tax_dependent: false,
      is_living_in_state: false,
      is_temp_out_of_state: false,
      has_other_income: false,
      has_deductions: false,
      has_enrolled_health_coverage: false
    )
  end
end

When(/^they view the financial assistance application for review$/) do
  visit financial_assistance.edit_application_path(application)
end

And(/^click the 'Review and Continue' button$/) do
  click_link "Continue"
end

And(/^they review and submit the application$/) do
  click_link 'Continue'
end

When(/^click the "([^"]*)" button$/) do |_rg1|
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^they are taken back to view all applications$/) do
  visit financial_assistance.applications_path
end

Then(/^they will see that their application has been submitted$/) do
  page.find(".interaction-click-control-start-new-application")
end

When(/^they click on the 'Add Income Adjustment' button$/) do
  click_link 'Add Income Adjustment'
end

When(/^they click on 'Add Benefit' button$/) do
  click_link 'Add Health Coverage'
end

# And(/^has added an benefit$/) do
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

And(/^they complete the form for the benefit$/) do
  find('#is_eligible').click
  find('#benefit_insurance_kind').select('Acf Refugee Medical Assistance')
  click_button 'CONTINUE'
end

Then(/^they should be taken back to the applicant's detail page$/) do

end
And(/^they should see the newly added benefit$/) do
  page.should have_content('Benefit Info Added.')
end

# When (/^they view the applicant's details page$/) do
#   page.should have_content('Edit Applicant')
# end

When(/^they click on 'Remove Benefit' button/) do
  find(:xpath, '//a[@data-method="delete"][span]').click
  page.accept_alert
end

When(/^they click on 'Remove Deduction' button$/) do
  find(:xpath, '//a[@data-method="delete"][span]').click
  page.accept_alert
end

And(/^they should be taken back to the application's details page for benefit$/) do
  page.should have_content("Health Coverage for #{consumer.person.first_name}")
end

## Remove Deduction

When(/^they click on 'Add Deduction' button$/) do
  click_link 'Add Deductions'
end

And(/^they complete the form for the deduction/) do
  find('#deduction_kind').select('Alimony Paid')
  find('#deduction_frequency_kind').select('quarterly')
  fill_in 'deduction[amount]', with: "2.2"
  # find_all(".interaction-choice-control-deduction-frequency-kind")[2].click
  fill_in 'deduction[start_on]', with: "10/11/2016"
  fill_in 'deduction[end_on]', with: "11/18/2016"
  click_button 'CONTINUE'
end

Given(/^the consumer has an income$/) do
  application.active_applicants.first.incomes.create(
    {
      :amount => '5000',
      :frequency_kind => 'monthly',
      :employer_name => 'Ideacrew',
      :start_on => '2017/01/01',
      :end_on => '2017/12/31',
      :employer_phone => {:kind => 'phone main', :full_phone_number => '202-222-2222'},
      :employer_address => {:kind => 'primary', :address_1 => '2nd St', :city => 'Washington', :state => 'DC', :zip => '20001'}
    }
  )
end

Given(/^the consumer has a benefit$/) do
  application.active_applicants.first.update_attributes has_enrolled_health_coverage: true
end

Given(/^the consumer has a deduction$/) do
  application.active_applicants.first.deductions.create! kind: 'alimony_paid'
end

And(/^they should see the newly added deduction$/) do
  page.should have_content('Deduction Added')
end

Then(/^they click on 'Remove deduction' button/) do
  page.find('.interaction-click-control-delete').click
  page.accept_alert
end

And(/^they should be taken back to the application's details page for deduction$/) do
  page.should have_content("Income Adjustments for #{application.applicant.first.first_name}")
end

Given(/^the FAA feature configuration is disabled$/) do
  disable_feature :financial_assistance
end

Given(/^the FAA feature configuration is enabled$/) do
  enable_feature :financial_assistance
end

Then(/^the consumer will not see the Cost Savings link$/) do
  expect(page).to have_no_link('Cost Savings')
end

And(/^the Cost Savings link is visible$/) do
  expect(page).to have_link('Cost Savings')
end

When(/^the consumer manually enters the "Cost Savings" url in the browser search bar$/) do
  visit financial_assistance.applications_path
end

Then(/^the consumer will not have access to the (.*) page$/) do |_title|
  expect(page).to have_content("The page you were looking for doesn't exist.")
end

When(/^the consumer clicks the Cost Savings link$/) do
  find_link('Cost Savings').click
end

Then(/^the consumer will navigate to the Cost Savings page$/) do
  expect(page).to have_selector('h1', text: 'Cost Savings Applications')
end

When(/^the consumer manually enters the "Help Paying for Coverage" url in the browser search bar$/) do
  visit help_paying_coverage_insured_consumer_role_index_path
end

Then(/^the consumer will navigate to the Help Paying for Coverage page$/) do
  expect(page).to have_selector('h2', text: 'Help Paying for Coverage')
end

Then(/^the consumer will navigate to the Family Members page$/) do
  expect(page).to have_selector('h2', text: "#{l10n('family_information')}")
end
