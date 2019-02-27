When(/^the system date is (greater|less) than the application_effective_date$/) do |compare|
  if compare == 'greater'
    allow(TimeKeeper).to receive(:date_of_record).and_return((@custom_plan_year.start_on + 5.days))
    TimeKeeper.date_of_record > @custom_plan_year.start_on == true
  else
    allow(TimeKeeper).to receive(:date_of_record).and_return((@custom_plan_year.start_on - 5.days))
    TimeKeeper.date_of_record < @custom_plan_year.start_on == true
  end
end

And(/^the system date is (greater|less) than the publish_due_day_of_month$/) do |compare|
  if compare == 'less'
    unless  TimeKeeper.date_of_record < @custom_plan_year.due_date_for_publish == true
      allow(TimeKeeper).to receive(:date_of_record).and_return((@custom_plan_year.due_date_for_publish - 1.day))
    end
  elsif compare == 'greater'
    unless TimeKeeper.date_of_record > @custom_plan_year.due_date_for_publish == true
      allow(TimeKeeper).to receive(:date_of_record).and_return((@custom_plan_year.due_date_for_publish + 1.day))
    end
  end
end

When (/^employer FTE count is (less than or equal|more than) to shop:small_market_employee_count_maximum$/) do |compare|
  if compare == 'less than or equal'
    @custom_plan_year.fte_count < Settings.aca.shop_market.small_market_employee_count_maximum
  elsif compare == 'more than'
    @custom_plan_year.update_attributes(fte_count: '65')
    @custom_plan_year.fte_count > Settings.aca.shop_market.small_market_employee_count_maximum
  end
end

And (/^employer primary address state (is|is not) DC$/) do |compare|
  if compare =='is'
    employer.primary_office_location.address.state == "DC"
  elsif compare == 'is not'
    employer.primary_office_location.address.update_attributes(state: "MA")
  end
end

When(/^the user clicks on Force Publish button$/) do
  find('.btn.btn-xs', text: 'Force Publish').click
end

When(/^the user clicks submit button$/) do
  find_button('Submit').trigger('click')
end

Then(/^a warning message will appear$/) do
  expect(find("#publishPlanYear .modal-body")).to have_content("As submitted, this application is ineligible for coverage under the DC Health Link exchange for reasons identified below. Click Cancel to go back and correct inaccurate information. If the information provided is accurate, you may click Publish to proceed. However, if you choose to proceed and the eligibility determination is deemed correct by DC Health Link officials, this organization may not again apply for coverage for 90 days, or until the reason for ineligibility changes, whichever is later.")
end

Then(/^the force publish successful message should be displayed$/) do
  expect(page).to have_content('Force Publish Successful')
end
