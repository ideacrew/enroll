# frozen_string_literal: true

Then(/^The user will navigate to the Help Paying for Coverage page$/) do
  visit financial_assistance.help_paying_coverage_applications_path
end

When(/^the user clicks CONTINUE$/) do
  if EnrollRegistry[:bs4_consumer_flow].enabled?
    ''
  else
    find(IvlChooseCoverage.continue_btn, wait: 5).click
  end
end

When(/^the user clicks the PREVIOUS link$/) do
  find('.interaction-click-control-previous').click
end

When(/^the user clicks the application checklist link$/) do
  find('.interaction-click-control-view-the-complete-application-checklist').click
end

Then(/the user will navigate to the Application Checklist/) do
  expect(page).to have_content("Application Checklist")
end

And(/^the date is within open enrollment$/) do
  allow(Settings.aca.individual_market.open_enrollment).to receive(:end_on).and_return(TimeKeeper.date_of_record + 1.day)
end

And(/^the date is after open enrollment$/) do
  allow(Settings.aca.individual_market.open_enrollment).to receive(:end_on).and_return(TimeKeeper.date_of_record - 1.day)
end

And(/^current hbx is under open enrollment$/) do
  HbxProfile.any_instance.stub(:under_open_enrollment?).and_return(true)
end

And(/^it is before open enrollment$/) do
  oe_start_on = HbxProfile.current_hbx.benefit_sponsorship.benefit_coverage_periods.detect {|bcp| bcp.start_on.year == Date.today.year}.open_enrollment_start_on
  allow(TimeKeeper).to receive(:date_of_record).and_return Date.new(oe_start_on.year,10,27)
end

And(/^it is after open enrollment$/) do
  oe_end_on = HbxProfile.current_hbx.benefit_sponsorship.benefit_coverage_periods.last.open_enrollment_end_on
  allow(TimeKeeper).to receive(:date_of_record).and_return Date.new(oe_end_on.year,2,15)
end

And(/^current hbx is not under open enrollment$/) do
  HbxProfile.any_instance.stub(:under_open_enrollment?).and_return(false)
end

Then(/^the oe application warning will display$/) do
  expect(page.has_css?(CostSavingsApplicationPage.oe_application_warning_display)).to eq true
end

Then(/^the oe application warning will not display$/) do
  expect(page.has_css?(CostSavingsApplicationPage.oe_application_warning_display)).to eq false
end

Then(/^the coverage update reminder warning will display$/) do
  expect(page.has_css?(CostSavingsApplicationPage.coverage_update_reminder_display)).to eq true
end

Then(/^the coverage update reminder warning will not display$/) do
  expect(page.has_css?(CostSavingsApplicationPage.coverage_update_reminder_display)).to eq false
end

Then(/^the index filter will display$/) do
  expect(page.has_css?(CostSavingsApplicationPage.index_with_filter)).to eq true
end

Then(/^the user will navigate to the assistance year selection page$/) do
  expect(page).to have_content(l10n("faa.year_selection_header"))
end

Then(/^the user will navigate to the assistance year selection page with multiple options$/) do
  oe_year = Family.application_applicable_year
  current_year = oe_year - 1
  expect(page).to have_content(l10n("faa.year_selection_header"))
  expect(page).to have_content(l10n("faa.assitance_year_option1", year: oe_year))
  expect(page).to have_content(l10n("faa.assitance_year_option2", year: current_year))
  expect(find("#renewal_assistance_year")).to be_checked
end

Then(/the user will navigate to the non-OE assistance year selection page/) do
  expect(page).to have_content(l10n('faa.year_selection_header'))
  expect(page).to have_content(l10n('faa.year_selection_subheader'))
  expect(page).to have_content(l10n('faa.choose_a_plan_year'))
  expect(page).to have_content(l10n('faa.non_oe_learn_more'))
end

When(/^the user clicks the SAVE & EXIT link$/) do
  find('.interaction-click-control-save---exit').click
end

Then(/^saves a YES answer to the question: Do you want to apply for Medicaid…$/) do
  find('span', text: 'Yes').click
  find('.btn', text: 'CONTINUE', wait: 5).click
end

Given(/^that the user is on the Application Checklist page$/) do
  financial_identifier = Person.all.first.financial_assistance_identifier
  application.update_attributes(family_id: financial_identifier)
  visit financial_assistance.application_checklist_application_path(application)
end

Then(/^the user will navigate to the FAA Household Infor: Family Members page$/) do
  expect(page).to have_content('Family Information')
end

Then(/^the next time the user logs in the user will see Application checklist page$/) do
  visit "/users/sign_in"
  fill_in "user_login", with: user_sign_up[:oim_id]
  fill_in "user_password", with: user_sign_up[:password]
  click_button "Sign in"
end
