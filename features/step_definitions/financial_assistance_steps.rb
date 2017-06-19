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

When(/^they click edit for an applicant$/) do
  click_link 'Add Info'
end

When(/^they complete and submit the tax information$/) do
  choose("is_required_to_file_taxes_yes")
  choose("is_claimed_as_tax_dependent_yes")
  click_button 'Next step'
  choose("is_ssn_applied_yes")
  choose("is_pregnant_yes")
  choose("is_self_attested_blind_yes")
  choose("has_daily_living_help_yes")
  choose("need_help_paying_bills_yes")
  choose("is_former_foster_care_yes")
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

When(/^they click on the 'Add Income' button$/) do
  click_link 'Add Income'
end

When(/^they complete the form for the income$/) do
  choose("yes2")
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
  find_all(".label")[2].click
  find_all(".interaction-choice-control-employer-address-state-2")[1].click
  fill_in 'employer_address[zip]', with: "22046"
  click_button 'Finish'
end

When(/^they click on 'Remove Income' button$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^they should be taken back to the application's details page$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^the income should be no longer be shown$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Given(/^has added an benefit$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

When(/^they click on 'Remove Benefit' button$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^the benefit should be no longer be shown$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Given(/^has added an deducation$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

When(/^they click on 'Remove Deducation' button$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^the deducation should be no longer be shown$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Given(/^the consumer has completed a financial assistance application$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

When(/^click the "([^"]*)" button$/) do |arg1|
  pending # Write code here that turns the phrase above into concrete actions
end

When(/^cthey review and submit the application$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^they are taken back to view all applications$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^they will see that their application has been submitted$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

When(/^they click on the 'Add Deducation' button$/) do
  pending # Write code here that turns the phrase above into concrete actions
end
