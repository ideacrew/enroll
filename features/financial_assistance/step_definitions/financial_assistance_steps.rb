# frozen_string_literal: true

Given(/^a consumer exists with family/) do
  consumer :with_consumer_role
end

Given(/^a consumer, with a family, exists$/) do
  consumer :with_nuclear_family
  hbx_profile = FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period)
  hbx_profile.benefit_sponsorship.benefit_coverage_periods.each do |bcp|
    ivl_product = FactoryBot.create(:benefit_markets_products_health_products_health_product, :ivl_product, application_period: (bcp.start_on..bcp.end_on))
    bcp.update_attributes!(slcsp_id: ivl_product.id)
  end
end

And(/^financial assistance primary applicant logs in$/) do
  login_as @financial_assistance_applicant_user
  visit financial_assistance.edit_application_path(@target_fa_application)
end

Given(/^is logged in$/) do
  login_as consumer, scope: :user
end

And(/^the consumer is RIDP verified$/) do
  consumer.person.consumer_role.move_identity_documents_to_verified
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

  # should be on application year select page now
  # TODO: Will need to be updated when year select logic implemented
  if EnrollRegistry.feature_enabled?(:iap_year_selection)
    find('.interaction-click-control-continue').click
    sleep 2
  end
  # should be on checklist page now
  find('a.interaction-click-control-continue').click
end

When(/^.+ click 'Start New Application' button$/) do
  click_button 'Start New Application'
end

Then(/^they should see a new finanical assistance application$/) do
  expect(page.current_url).to match("/applications/.*/edit")
  expect(page).to have_content(l10n('insured.family_members.index.continue_to_get_insurance'), wait: 10)
end

Given(/IAP Assistance Year Display feature is enabled/) do
  allow(EnrollRegistry[:iap_assistance_year_display].feature).to receive(:is_enabled).and_return(true)
  allow(FinancialAssistanceRegistry[:iap_assistance_year_display].feature).to receive(:is_enabled).and_return(true)
end

Given(/IAP Assistance Year Display feature is disabled/) do
  allow(EnrollRegistry[:iap_assistance_year_display].feature).to receive(:is_enabled).and_return(false)
  allow(FinancialAssistanceRegistry[:iap_assistance_year_display].feature).to receive(:is_enabled).and_return(false)
end

Then(/They should see the application assistance year above Info Needed/) do
  application = FinancialAssistance::Application.all.first
  assistance_year = assistance_year_display(application)

  expect(page).to have_content(assistance_year[0..1])
  expect(page).to have_content(assistance_year[2..3])
end

Then(/They should not see the application assistance year above Info Needed/) do
  expect(page).to have_content('Your Application for Premium Reductions')
  expect(page).to_not have_content(l10n('faa.application_for_coverage'))
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
  sleep 5
  expect(page).to have_selector("[data-cuke='tax_info_header']")
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

Then(/^.+ should see a JS alert$/) do
  sleep 1
  page.driver.browser.switch_to.alert.accept
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

And(/^the consumer has an esi benefit$/) do
  application.active_applicants.first.benefits.create(
    {
      "employee_cost" => {"cents" => 58_800.0, "currency_iso" => "USD"},
      "workflow" => {},
      "employer_id" => "13-9845789",
      "kind" => "is_enrolled",
      "insurance_kind" => "employer_sponsored_insurance",
      "employer_name" => "Acme",
      "is_esi_waiting_period" => true,
      "is_esi_mec_met" => false,
      "esi_covered" => "self",
      "start_on" => TimeKeeper.date_of_record.beginning_of_year,
      "end_on" => nil,
      "employee_cost_frequency" => "monthly",
      "submitted_at" => TimeKeeper.date_of_record,
      "employer_phone" => {"kind" => "work", "area_code" => "394", "number" => "5789753", "full_phone_number" => "3945789753"}
    }
  )
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

Given(/^the primary caretaker question configuration is enabled$/) do
  enable_feature :primary_caregiver_other_question, {registry_name: FinancialAssistanceRegistry}
end

Given(/^the primary caretaker question configuration is diasbled$/) do
  disable_feature :primary_caregiver_other_question, {registry_name: FinancialAssistanceRegistry}
end

Given(/^the primary caretaker relationship question configuration is enabled$/) do
  enable_feature :primary_caregiver_relationship_other_question, {registry_name: FinancialAssistanceRegistry}
end

Given(/^the FAA feature configuration is disabled$/) do
  disable_feature :financial_assistance
end

Given(/^the kaiser paynow feature configuration is enabled$/) do
  enable_feature :kaiser_permanente_pay_now
end

Given(/^the kaiser paynow feature configuration is disabled$/) do
  disable_feature :kaiser_permanente_pay_now
end

When(/kaiser pay now feature is enabled/) do
  allow(EnrollRegistry[:kaiser_permanente_pay_now].feature).to receive(:is_enabled).and_return(true)
  allow(EnrollRegistry[:kaiser_permanente_pay_now].setting(:plan_shopping)).to receive(:item).and_return(true)
end

Given(/^the enrollment tile feature is enabled$/) do
  skip_this_scenario unless EnrollRegistry[:kaiser_pay_now].setting(:enrollment_tile).item || EnrollRegistry[:anthem_blue_cross_and_blue_shield_pay_now].setting(:enrollment_tile).item
end

Given(/^the generic_redirect setting is enabled$/) do
  allow(EnrollRegistry[:generic_redirect].feature).to receive(:is_enabled).and_return(true)
end

Given(/^the generic_redirect setting is disabled$/) do
  allow(EnrollRegistry[:generic_redirect].feature).to receive(:is_enabled).and_return(false)
end

Given(/^the FAA feature configuration is enabled$/) do
  enable_feature :financial_assistance
end

Given(/^the MEC check feature configuration is enabled$/) do
  enable_feature :mec_check
end

Given(/^the consumer has received a successful MEC check response$/) do
  consumer.person.mec_check_response = "Success"
end

Given(/an applicant has outstanding local mec evidence/) do
  application.active_applicants.first.update_attributes!(local_mec_evidence: FactoryBot.build(:evidence, key: 'local_mec', aasm_state: 'outstanding'))
  application.active_applicants.first.save!
end

Given(/the mec check feature is enabled/) do
  allow(EnrollRegistry[:mec_check].feature).to receive(:is_enabled).and_return(true)
end

Given(/the mec check feature is disabled/) do
  allow(EnrollRegistry[:mec_check].feature).to receive(:is_enabled).and_return(false)
end

Given(/the shop coverage check feature is enabled/) do
  allow(EnrollRegistry[:shop_coverage_check].feature).to receive(:is_enabled).and_return(true)
end

Given(/the shop coverage check feature is disabled/) do
  allow(EnrollRegistry[:shop_coverage_check].feature).to receive(:is_enabled).and_return(false)
end

Given(/the coverage check banners feature is enabled/) do
  allow(EnrollRegistry[:coverage_check_banners].feature).to receive(:is_enabled).and_return(true)
end

Given(/the coverage check banners feature is disabled/) do
  allow(EnrollRegistry[:coverage_check_banners].feature).to receive(:is_enabled).and_return(false)
end

Given(/an applicant has shop coverage/) do
  applicant = application.active_applicants.first
  person = FactoryBot.create(:person, :with_family)
  fm = person.primary_family.family_members.where(person_id: person.id).first
  hbx = FactoryBot.create(:hbx_enrollment, family: person.primary_family)
  hbx.hbx_enrollment_members << FactoryBot.build(:hbx_enrollment_member, applicant_id: fm.id)
  hbx.save!
  applicant.update_attributes!(person_hbx_id: person.hbx_id)
end

Given(/^american indian or alaska native income feature is enabled$/) do
  enable_feature :american_indian_alaskan_native_income
end

Given(/^american indian or alaska native income feature is disabled$/) do
  disable_feature :american_indian_alaskan_native_income
end

Given(/the iap year selection feature is enabled/) do
  enable_feature :iap_year_selection, {registry_name: FinancialAssistanceRegistry}
  enable_feature :iap_year_selection
end

Given(/the iap year selection form feature is enabled/) do
  enable_feature :iap_year_selection_form, {registry_name: FinancialAssistanceRegistry}
  enable_feature :iap_year_selection_form
end

Given(/the iap year selection form feature is disabled/) do
  disable_feature :iap_year_selection_form, {registry_name: FinancialAssistanceRegistry}
  disable_feature :iap_year_selection_form
end

Given(/the oe application warning display feature is enabled/) do
  enable_feature :oe_application_warning_display, {registry_name: FinancialAssistanceRegistry}
  enable_feature :oe_application_warning_display
end

Given(/the filtered_application_list feature is enabled/) do
  enable_feature :filtered_application_list, {registry_name: FinancialAssistanceRegistry}
  enable_feature :filtered_application_list
end

Given(/the iap year selection feature is disabled/) do
  disable_feature :iap_year_selection, {registry_name: FinancialAssistanceRegistry}
  disable_feature :iap_year_selection
end

Given(/^expands the "Other Options" panel/) do
  # TODO: Maybe figure out how to do this with something other than glyphicon
  other_actions_link = page.all('a').detect { |link| link[:id] == 'open_button' }
  other_actions_link.click
  expect(page).to have_content(
    l10n(
      "faa.full_long_name_determination",
      program_long_name: FinancialAssistanceRegistry[:medicaid_or_chip_agency_long_name].setting(:name).item,
      program_short_name: FinancialAssistanceRegistry[:medicaid_or_chip_program_short_name].setting(:name).item
    )
  )
  find_link(
    l10n(
      "faa.send_to_external_verification"
    )
  ).disabled?.should eql(false)
end

Given(/clicks the "Send To OFI" button/) do
  find_link(l10n("faa.send_to_external_verification"))
  click_link(l10n("faa.send_to_external_verification"))
end

Then(/^the user should see the external verification link$/) do
  # TODO: Maybe figure out how to do this with something other than glyphicon
  # other_actions_link = page.all('a').detect { |link| link[:class] == 'glyphicon glyphicon-plus pull-right' }
  # other_actions_link.click
  expect(page).to have_content(
    l10n(
      "faa.full_long_name_determination",
      program_long_name: FinancialAssistanceRegistry[:medicaid_or_chip_agency_long_name].setting(:name).item,
      program_short_name: FinancialAssistanceRegistry[:medicaid_or_chip_program_short_name].setting(:name).item
    )
  )
end

Then(/the "Send To OFI" button will be disabled and the user will see the button text changed to "Sent To OFI"/) do
  find_link(
    l10n(
      "faa.sent_to_external_verification"
    )
  )['disabled'].should eql('true')

  expect(page).to have_link(
    l10n(
      "faa.sent_to_external_verification"
    )
  )
end

Then(/^they should see the Medicaid Currently Enrolled warning text$/) do
  expect(page).to have_selector('#mec-check-response')
  expect(page).to have_content(l10n('faa.mc_continue_bold'))
end

Then(/^they should see the shop coverage exists warning text$/) do
  expect(page).to have_content(l10n('faa.shop_check_success'))
  expect(page).to have_content(l10n('faa.mc_continue_bold'))
end

Then(/^they should not see the shop coverage exists warning text$/) do
  expect(page).to_not have_content(l10n('faa.shop_check_success'))
  expect(page).to_not have_content('faa.mc_continue_bold')
end

# TODO: Refactor these with the resource_registry_world.rb helpers
Given(/^Indian Health Service Question feature is enabled$/) do
  enable_feature :indian_health_service_question
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
  expect(page).to have_content('Cost Savings Applications', wait: 10)
end

Then(/the application year will be present on the table/) do
  expect(page).to have_content('APPLICATION YEAR')
end

When(/^the consumer manually enters the "Help Paying for Coverage" url in the browser search bar$/) do
  visit help_paying_coverage_insured_consumer_role_index_path
end

Then(/^the consumer will navigate to the Help Paying for Coverage page$/) do
  expect(page).to have_selector('h2', text: 'Your Application for Premium Reductions')
end

Then(/^the consumer will navigate to the Family Members page$/) do
  expect(page).to have_selector('h2', text: l10n('family_information').to_s)
end

Then(/^a family with financial application in (.*) state exists$/) do |state|
  create_family_faa_application(state)
end

Then(/^a family with financial application and applicants in (.*) state exists$/) do |state|
  create_family_faa_application_with_applicants(state)
end

Then(/^a family with financial application and applicants in (.*) state exists with evidences$/) do |state|
  create_family_faa_application_with_applicants_and_evidences(state)
end

Then(/^a family with financial application and applicants in (.*) state exists with unverified evidences$/) do |state|
  create_family_faa_application_with_applicants_and_unverified_evidences(state)
end

When(/^an applicant with other income exists for a (.*) financial application$/) do |state|
  create_application_applicant_with_incomes(state)
end

Then(/^the user with (.*) role is logged in$/) do |role|
  @user.roles << role
  login_as @user
end

And(/^the ssi_income_types feature is enabled$/) do
  enable_feature :ssi_income_types, {registry_name: FinancialAssistanceRegistry}
end

And(/^.+ clicks on Cost Savings link$/) do
  find_link('Cost Savings').click
end

And(/^.+ should see 'Start New Application' button$/) do
  expect(page).to have_css('.interaction-click-control-start-new-application')
end

When(/^.+ clicks on Action dropdown$/) do
  find('.interaction-click-control-actions').click
end

Then(/^the .+ should see text Full Application$/) do
  expect(page).to have_content('Full Application')
end

Then(/^.+ clicks on Full application action$/) do
  click_link 'Full Application'
end

Then(/^the social security type - (.*) benefits should show$/) do |ssi_type|
  expect(page).to have_content(l10n("faa.income.social_security_benefit.#{ssi_type}"))
end

Then(/^the (.*) type should display$/) do |income_type|
  expect(page).to have_content(l10n("faa.income.#{income_type.parameterize.underscore}"))
end

Then(/^the caretaker questions should show$/) do
  expect(page).to have_content(l10n("faa.other_ques.primary_caretaker_question_text", subject: l10n("faa.other_ques.this_person")).split(' *').first)
  expect(page).to have_content(l10n("faa.review.coverage.caretaker"))
end

Then(/^.+ should see county under Mailing and Home address$/) do
  expect(page).to have_content('COUNTY')
  expect(page).to have_content('Cumberland')
end

Then(/^user should land on full application page and should see 2 view my applications buttons$/) do
  expect(page).to have_css('.interaction-click-control-view-my-applications', count: 2)
end

Then(/^user should see 2 print buttons$/) do
  expect(page).to have_css('.interaction-click-control-print', count: 2)
end

And(/^user should see Medicaid eligibility question$/) do
  expect(page).to have_content("Medicaid eligibility")
end

And(/^user should have feature toggled questions in review$/) do
  # Add more stuff here as you add more conditional questions please, fam
  if EnrollRegistry.feature_enabled?(:financial_assistance) &&
     FinancialAssistanceRegistry.feature_enabled?(:primary_caregiver_other_question)
    expect(page).to have_content(l10n("faa.other_ques.primary_caretaker_question_text", subject: l10n("faa.other_ques.this_person")))
  end
end

And(/an applicant has an existing non ssn apply reason/) do
  application.applicants.first.update_attributes!(non_ssn_apply_reason: 'ApplicantWillProvideSSNLater',
                                                  no_ssn: '1',
                                                  is_ssn_applied: false)
end

And(/the user will see the applicant's is ssn applied answer/) do
  page.has_css?(FinancialAssistance::ReviewApplicationPage.is_ssn_applied)
end

And(/the user will see the applicant's non ssn apply reason/) do
  page.has_css?(FinancialAssistance::ReviewApplicationPage.non_ssn_apply_reason)
end

And(/^the user should click on the destroy applicant icon$/) do
  find_all('.close-2')[2].click
  find('.fa-times').click
end

Then(/^user should see need help paying question$/) do
  page.has_css?(FinancialAssistance::ReviewApplicationPage.need_help_paying_bills)
end

And(/^user should have an answer related to applicant$/) do
  page.has_css?(FinancialAssistance::ReviewApplicationPage.applicant_paying_bills)
end

Then(/^the user should see the popup for the remove applicant confirmation$/) do
  popup_text = "Are you sure you want to remove this applicant?"
  expect(page).to have_content(popup_text)
end

And(/^all applicants are not medicaid chip eligible and are non magi medicaid eligible$/) do
  application.applicants.each do |applicant|
    applicant.update_attributes(is_medicaid_chip_eligible: false)
    applicant.update_attributes(is_non_magi_medicaid_eligible: false)
  end
end

And(/^there is a (.*) evidence present with the option to upload a document$/) do |evidence_type|
  evidence = application.applicants.first.send("#{evidence_type}_evidence".to_sym)
  # confirm evidence is visible
  find("#evidence_kind_#{evidence_type}_evidence")
  # confirm id on hidden input for upload is present
  find(:xpath, "//input[@id='upload_evidence_#{evidence.id}']", :visible => false)
end
