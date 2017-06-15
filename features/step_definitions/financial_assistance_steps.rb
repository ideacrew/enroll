Given(/^a consumer, with a family, exists$/) do
  consumer :with_family
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
  binding.pry
end

Given(/^the consumer has started a financial assistance application$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

When(/^they view the financial assistance application$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

When(/^they click edit for an applicant$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

When(/^they complete and submit the tax infomration$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^they should be taken to the applicant's details page$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^see some of the tax information on the applicant's detail page$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Given(/^has added tax information for an applicant$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

When(/^they view the applicant's details page$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

When(/^they click on the 'Add Income' button$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

When(/^they complete the form for the income$/) do
  pending # Write code here that turns the phrase above into concrete actions
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
