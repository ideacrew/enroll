include Config::SiteHelper

When(/^the system date is (greater|less) than the application_effective_date$/) do |compare|
  if compare == 'greater'
    allow(TimeKeeper).to receive(:date_of_record).and_return((initial_application.effective_period.min + 5.days))
    TimeKeeper.date_of_record > initial_application.effective_period.min == true
  else
    allow(TimeKeeper).to receive(:date_of_record).and_return((initial_application.effective_period.min - 5.days))
    TimeKeeper.date_of_record < initial_application.effective_period.min == true
  end
end

And(/^the system date is (greater|less) than the publish_due_day_of_month$/) do |compare|
  if compare == 'less'
    unless  TimeKeeper.date_of_record < initial_application.last_day_to_publish == true
      allow(TimeKeeper).to receive(:date_of_record).and_return((initial_application.last_day_to_publish - 1.day))
    end
  elsif compare == 'greater'
    unless TimeKeeper.date_of_record > initial_application.last_day_to_publish == true
      allow(TimeKeeper).to receive(:date_of_record).and_return((initial_application.last_day_to_publish + 1.day))
    end
  end
end

When(/^the system date is (.*?) open_enrollment_period start date$/) do |compare|
  if compare == 'greater than'
    allow(TimeKeeper).to receive(:date_of_record).and_return((initial_application.effective_period.min + 15.days))
    TimeKeeper.date_of_record > initial_application.open_enrollment_period.min == true
  end
end

When(/^the user clicks on Force Publish button$/) do
  find('.btn.btn-xs', text: 'Force Publish').click
end

And(/^the user clicks submit button$/) do
  find_button('Submit').trigger('click')
end

When (/^(.*?) FTE count is (less than or equal|more than) to shop:small_market_employee_count_maximum$/) do |employer, compare|
  if compare == 'less than or equal'
    initial_application.update_attributes(fte_count: fte_max_count - 1 )
  elsif compare == 'more than'
    initial_application.update_attributes(fte_count: fte_max_count + 5)
  end
end

And (/^(.*?) primary address state (is|is not) MA$/) do |employer, compare|
  if compare =='is'
    unless initial_application.sponsor_profile.is_primary_office_local?
      initial_application.benefit_sponsorship.profile.primary_office_location.address.update_attributes(state: Settings.aca.state_abbreviation.to_s.downcase)
    end
  elsif compare == 'is not'
    if initial_application.sponsor_profile.is_primary_office_local?
      initial_application.benefit_sponsorship.profile.primary_office_location.address.update_attributes(state: '')
    end
  end
end

Then(/^a warning message will appear$/) do
  expect(find("#submitBenefitApplication .modal-body")).to have_content("If you submit this application as is, the small business application may be ineligible for coverage through the Health Connector because it does not meet the eligibility reason(s) identified below:")
end

And(/^ask to confirm intention to publish$/) do
  page.driver.browser.accept_confirm
end

And(/^the user clicks publish anyways$/) do
  find('a', :text => "Publish Anyways").click
end

Then(/^the force publish successful message should be displayed$/) do 
  expect(page).to have_content('Force Publish Successful')
end

Then(/^the user will see published sucessfully for review message$/) do
  expect(page).to have_content('Employer(s) Plan Year was successfully submitted for review')
end
