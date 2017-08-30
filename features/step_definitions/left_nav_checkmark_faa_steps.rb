Given(/^that an FAA application is in the draft state$/) do
  login_as consumer, scope: :user
  visit financial_assistance_applications_path
  create_plan
  click_button "Start new application"
end

Given(/^the user is on FAA Household Info: Family Members page$/) do
  expect(page).to have_content('Household Info: Family Members')
  consumer.person.families.last.family_members.each do |family_member|
    expect(page).to have_content(family_member.first_name)
  end
  expect(page).to have_content('Household Info: Family Members')
  find(".btn", text: "CONTINUE").click
end

When(/^a driver question is answered with NO$/) do
  find("#income_from_employer_no").click
  find("#self_employed_no").click
  find("#other_income_no").click
  find("#adjustments_income_no").click
  find("#enrolled_in_coverage_no").click
  find("#access_to_other_coverage_no").click
end

And(/^the user saves the answer$/) do
  find(:xpath, "//input[@value='CONTINUE'][@name='commit']").click
end

Then(/^the corresponding section should be WHITE background & GREY text$/) do
  page.should have_xpath('//a[@class="cna disabled interaction-click-control-income"]')
  page.should have_xpath('//a[@class="cna disabled interaction-click-control-income-adjustments"]')
  page.should have_xpath('//a[@class="cna disabled interaction-click-control-health-coverage"]')
end

And(/^a check mark will not appear on the left nav for that section$/) do
  page.should_not have_xpath('//a[@class="interaction-click-control-tax-info"]/span[@class="fa fa-check applicant-check"]')
end

Then(/^the all other sections are confirmed as complete$/) do
  find("#is_required_to_file_taxes_yes").click
  find("#is_claimed_as_tax_dependent_no").click
  find(:xpath, "//input[@value='CONTINUE'][@name='commit']").click
  page.should have_xpath('//a[@class="interaction-click-control-tax-info"]/span[@class="fa fa-check applicant-check"]')
end

And(/^the applicant is complete$/) do
  find("#is_pregnant_no").click
  find("#is_post_partum_period_no").click
  find("#is_self_attested_blind_no").click
  find("#has_daily_living_no").click
  find("#has_daily_living_help_no").click
  find(:xpath, "//input[@value='CONTINUE'][@name='commit']").click
  page.should have_xpath('//span[@class="complete-icon"]')
end