And(/^saves a YES answer to the question: Do you want to apply for Medicaid…$/) do
  find(:xpath, '//label[@for="radio1"]').click
  create_plan
  find('.btn', text: 'CONTINUE').click
end

Given(/^that the user is on the Application Checklist page$/) do
  visit application_checklist_financial_assistance_applications_path
end

Then(/^the user will navigate to the FAA Household Info page$/) do
  expect(page).to have_content('Household Info: Family Members')
end