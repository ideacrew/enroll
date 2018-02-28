Then(/^they visit the Health Coverage page via the left nav \(also confirm they are on the Health Coverage page\)$/) do
  visit financial_assistance_application_applicant_benefits_path(application.id, application.primary_applicant.id)
end

Given(/^the user answers no to currently having health coverage$/) do
  choose('has_enrolled_health_coverage_false')
  sleep 1
end

Then(/^the health coverage choices should not show$/) do
  expect(page).not_to have_xpath("//*[@id='enrolled-benefit-kinds']")
end

Given(/^the user answers yes to currently having health coverage$/) do
  choose('has_enrolled_health_coverage_true')
  sleep 1
end

Then(/^the health coverage choices should show$/) do
  expect(page).to have_xpath("//*[@id='enrolled-benefit-kinds']")
end

Given(/^the user answers no to currently having access to other health coverage$/) do
  choose('has_eligible_health_coverage_false')
  sleep 1
end

Then(/^the other health coverage choices should not show$/) do
  expect(page).not_to have_xpath("//*[@id='eligible-benefit-kinds']")
end

Given(/^the user answers yes to currently having access to other health coverage$/) do
  choose('has_eligible_health_coverage_true')
  sleep 1
end

Then(/^the other health coverage choices should show$/) do
  expect(page).to have_xpath("//*[@id='eligible-benefit-kinds']")
end