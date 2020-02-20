include Config::SiteHelper

When(/^the system date is (greater) than the earliest_start_prior_to_effective_on$/) do |compare|
  if compare == 'greater'
    allow(TimeKeeper).to receive(:date_of_record).and_return((initial_application.effective_period.min + 15.days))
    TimeKeeper.date_of_record > initial_application.effective_period.min == true
  end
end

When(/^the system date is (less) than the monthly_open_enrollment_end_on$/) do |compare|
  if compare == "less"
    TimeKeeper.date_of_record < initial_application.open_enrollment_period.max == true
  end
end

And(/^the system date is (greater|less) than the publish_due_day_of_month$/) do |compare|
  if compare == 'less'
    TimeKeeper.date_of_record.day < initial_application.publish_due_day_of_month == true
  elsif compare == 'greater'
    allow(TimeKeeper).to receive(:date_of_record).and_return((initial_application.open_enrollment_period.max - 1.day))
    TimeKeeper.date_of_record.day > initial_application.publish_due_day_of_month == true
  end
end

When(/^the system date is (greater|less) than the monthly open enrollment end_on$/) do |compare|
  if compare == 'less'
    TimeKeeper.date_of_record < initial_application.open_enrollment_period.max == true
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
  find('input.btn-primary').click
end

Then(/^the force published action should display 'Employer\(s\) Plan Year was successfully published'$/) do
  sleep 2
  expect(page).to have_content('Employer(s) Plan Year was successfully published')
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

Then (/^a (less than or equal|more than) warning message will appear$/) do |compare|
  if compare == 'less than or equal'
    expect(page).to have_content("Small business NOT located in #{Settings.aca.state_name}")
  elsif compare == 'more than'
    expect(page).to have_content("Small business should have 1 - #{Settings.aca.shop_market.small_market_employee_count_maximum} full time equivalent employees")
  end
end

And(/^ask to confirm intention to publish.$/) do
  page.driver.browser.accept_confirm
end
