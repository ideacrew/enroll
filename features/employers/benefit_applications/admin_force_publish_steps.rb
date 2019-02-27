include Config::SiteHelper

When(/^the system date is (greater|less) than the earliest_start_prior_to_effective_on$/) do |compare|
  if compare == 'greater'
    allow(TimeKeeper).to receive(:date_of_record).and_return((initial_application.effective_period.min + 15.days))
    TimeKeeper.date_of_record > initial_application.effective_period.min == true
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
  find('.btn.btn-xs', text: 'Force Publish').trigger('click')
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
  expect(page.driver.browser.modal_message).to have_content('Can not publish due to fte count out range or primary office location out of MA, Publish anyway?')
end

And(/^ask to confirm intention to publish.$/) do
  page.driver.browser.accept_confirm
end
