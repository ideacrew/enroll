# frozen_string_literal: true

And(/^.+ sees the list of plans$/) do
  find('#planContainer', wait: 10)
  expect(page).to have_link('Select')
  # screenshot("plan_shopping")
end

When(/(.*) clicks "(.*?)" link in the qle carousel/) do |_name, qle_event|
  click_link qle_event.to_s
end

When(/(.*) selects a current qle date/) do |_person|
  expect(page).to have_content "Married"
  # screenshot("past_qle_date")
  fill_in "qle_date", :with => TimeKeeper.date_of_record.strftime("%m/%d/%Y")
  within '#qle-date-chose' do
  
    find('.interaction-click-control-continue')
    if !page.has_content?("Based on the information you entered, you may be eligible to enroll now but there is limited time")
      find('.interaction-click-control-continue').click
    end
  end
end

Then(/(.*) sees the QLE confirmation message and clicks on continue$/) do |_person|
  expect(page).to have_content "Based on the information you entered, you may be eligible to enroll now but there is limited time"
  # screenshot("valid_qle")
  click_button "Continue"
end

When(/^.+ sees the new dependent form$/) do
  expect(page).to have_content('CONFIRM MEMBER')
end

When(/^.+ enters? the info of his dependent wife$/) do
  fill_in EmployeeFamilyInformation.dependent_first_name, with: 'Cynthia'
  fill_in EmployeeFamilyInformation.dependent_last_name, with: 'Patrick'
  fill_in EmployeeFamilyInformation.dependent_ssn, with: '123445678'
  fill_in EmployeeFamilyInformation.dependent_dob, with: '09/15/1994'
  find(EmployeeFamilyInformation.female_radiobtn).click
  sleep 1
  find(EmployeeFamilyInformation.dependent_relationship_dropdown).click
  find(EmployeeFamilyInformation.spouse).click
  find(EmployeeFamilyInformation.lives_with_primary).click
  fill_in EmployeeFamilyInformation.dependent_address_line_one, with: '123 STREET'
  fill_in EmployeeFamilyInformation.dependent_city, with: 'WASHINGTON'
  find(EmployeeFamilyInformation.dependent_select_state_dropdown).click
  find(EmployeeFamilyInformation.dependent_select_dc_state).click
  fill_in EmployeeFamilyInformation.dependent_zip, with: '01001'
  sleep 5
end

Then(/(.*) should see his active enrollment including his wife$/) do |_person|
  sleep 1
  expect(page).to have_content "Cynthia"
end
