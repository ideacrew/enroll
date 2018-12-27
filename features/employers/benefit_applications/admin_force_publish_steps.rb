include Config::SiteHelper
def date_range(date, month)
  start_date = (date + month.months).beginning_of_month
  end_date = (start_date + 12.months).end_of_month
  (start_date..end_date)
end

When(/^the system date is (greater|less) than the earliest_start_prior_to_effective_on$/) do |compare|
  if compare == 'less'
    initial_application.update_attributes(effective_period: date_range(Date.today, 3))
  elsif compare == 'greater'
    initial_application.update_attributes(effective_period: effective_period)
  end
end

And(/^the system date is (greater|less) than the publish_due_day_of_month$/) do |compare|
  current_date = Date.current
  day = compare == 'greater' ? 18 : 13
  expect(Date).to receive(:today).and_return(current_date)
  expect(current_date).to receive(:day).and_return(day)
end

When(/^the system date is (greater|less) than the monthly open enrollment end_on$/) do |compare|
  if compare == 'less'
    initial_application.update_attributes(open_enrollment_period: date_range(Date.today, 1))
  elsif compare == 'greater'
    initial_application.update_attributes(open_enrollment_period: effective_period)
  end
end

When(/^the system date is (.*?) open_enrollment_period start date$/) do |compare|
  if compare == 'greater than'
    initial_application.update_attributes(open_enrollment_period: date_range(Date.today - 2.months, 1))
  elsif ['less than', 'equal to'].include?(compare)
    initial_application.update_attributes(open_enrollment_period: date_range(Date.today, 1))
  end
end

When(/^the user clicks on Force Publish button$/) do
  find('.btn.btn-xs', text: 'Force Publish').trigger('click')
end

Then(/^the force published action should display '(.*?)'$/) do |message|
  expect(page).to have_content(message)
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


