Then(/^Hbx Admin should see an DC Resident Application link$/) do
  find_link("#{EnrollRegistry[:enroll_app].setting(:state_abbreviation).item} Resident Application").visible?
end

Then(/^Hbx Admin should not see an New DC Resident Application link$/) do
  expect(page).not_to have_content('New DC Resident Application')
end

Then(/^Hbx Admin should see a DC Resident Application link disabled$/) do
  find_link("#{EnrollRegistry[:enroll_app].setting(:state_abbreviation).item} Resident Application")[:class].include?("blocking") == false
end

When(/^Hbx Admin clicks on New DC Resident Application link$/) do
  find(:xpath, "//*[@id='inbox']/div/div[3]/div/span/div[1]/ul/li[3]/a").click
end

Then(/^Hbx Admin should not see an New Consumer Phone Application link and New Consumer Paper Application link$/) do
  expect(page).not_to have_content('New Consumer Phone Application')
  expect(page).not_to have_content('New Consumer Paper Application')
end

When(/^Hbx Admin clicks on DC Resident Application link$/) do
  find_link("#{EnrollRegistry[:enroll_app].setting(:state_abbreviation).item} Resident Application").click
end

Then(/^Hbx Admin should see DC Resident Personal Information page$/) do
  expect(page).to have_content('Personal Information')
end

When(/Hbx Admin goes to register a user as individual$/) do
  step "I use unique values"
  fill_in IvlPersonalInformation.first_name, :with => "Carlos"
  fill_in IvlPersonalInformation.last_name, :with => "Devina"
  fill_in 'jq_datepicker_ignore_person[dob]', :with => (@u.adult_dob :adult_dob)
  find(IvlPersonalInformation.male_radiobtn).click
  find('.btn', text: 'CONTINUE').click
end

Then(/^Hbx Admin clicks on continue button$/) do
  click_link "Continue"
end

Then(/Hbx Admin should see a form to enter personal information$/) do
  find(IvlPersonalInformation.incarcerated_no_radiobtn).click
  fill_in IvlPersonalInformation.address_line_one, :with => "4900 USAA BLVD"
  fill_in IvlPersonalInformation.address_line_two, :with => "212"
  fill_in IvlPersonalInformation.city, :with => "Washington"
  find(IvlPersonalInformation.select_state_dropdown).click
  find('li[data-index="9"]').click
  fill_in IvlPersonalInformation.zip, :with => "20002"
  # expect(page).to have_css("#home_address_tooltip")
  find('.btn', text: 'CONTINUE').click
end

Then(/^Hbx Admin should see text Household Info$/) do
  expect(page).to have_content("#{l10n('family_information')}")
  expect(page).to have_content('get health insurance coverage for other members of your family')
  find_link('Add Member').visible?
  find('.btn', text: 'CONTINUE').click
end

Then(/^Hbx Admin should see text Special Enrollment Period$/) do
  FactoryBot.create(:qualifying_life_event_kind, market_kind: "individual")
  sleep 2
  expect(page).to have_content('Special Enrollment Period')
  expect(page).to have_content('TOP LIFE CHANGES')
  expect(page).to have_content('Married')
end

When(/Hbx Admin clicks "(.*?)" in qle carousel/) do |qle_event|
  click_link "#{qle_event}"
end

When(/Hbx Admin select a past qle date/) do
  expect(page).to have_content "Married"
  # screenshot("past_qle_date")
  fill_in "qle_date", :with => (TimeKeeper.date_of_record - 5.days).strftime("%m/%d/%Y")
  find('h1').click
  within '#qle-date-chose' do
    click_link "CONTINUE"
  end
end

Then(/Hbx Admin should see confirmation and clicks continue/) do
  expect(page).to have_content "Based on the information you entered, you may be eligible to enroll now but there is limited time"
  click_button "Continue"
end

When(/Hbx Admin selects a plan from shopping plan page/) do
  find(:xpath, '//*[@id="ivl_plans"]/div[1]/div/div[5]/div[3]/a[1]').click
end

Then(/Hbx Admin should see the summary page of plan selection/) do
  expect(page).to have_content('Confirm Your Plan Selection')
  # screenshot("summary_page")
end

When(/Hbx Admin clicks on Confirm button on the summary page of plan selection/) do
  find(IvlConfirmYourPlanSelection.i_agree_checkbox).click
  fill_in IvlConfirmYourPlanSelection.first_name, :with => "Carlos"
  fill_in IvlConfirmYourPlanSelection.last_name,  :with => "Devina"
  find('.btn', text: 'CONFIRM').click
end

Then(/Hbx Admin should see the enrollment receipt page/) do
  expect(page).to have_content('Enrollment Submitted')
  # screenshot("receipt_page")
end

When(/HBX Admin clicks go to my account button/) do
  find('.btn', text: 'GO TO MY ACCOUNT').click
end

When(/(.*) is clicked by HBX Admin/) do |btn|
  find('.btn', text: btn).click
end

Then(/Hbx Admin should see the home page with text coverage selected/) do
  expect(page).to have_content('Coverage Selected')
  # screenshot("home_page")
end

Then(/^Hbx Admin should see broker assister search box$/) do
  expect(page).to have_content('Select a Broker or Assister')
end

Then(/^Hbx Admin should see an Transition family members link$/) do
  find_link('Transition Family Members').visible?
end

When(/^Hbx Admin clicks Transition family members link$/) do
  FactoryBot.create(:qualifying_life_event_kind, reason: 'eligibility_failed_or_documents_not_received_by_due_date', title: 'Not eligible for marketplace coverage due to citizenship or immigration status')
  click_link('Transition Family Members')
end

Then(/^Hbx Admin should see the form being rendered to transition each family members seperately$/) do
  expect(page).to have_content(/Transition Family Members/i)
  expect(page).to have_content(/Transition User?/i)
end

When(/^Hbx Admin enter\/update information of each member individually$/) do
  find("#transition_user", wait: 5).click
  find('input.date-picker').click
  find('.ui-state-highlight', wait: 5).click
end

When(/^Hbx Admin clicks submit button$/) do
  click_button 'Submit'
end

Then(/^Hbx Admin should show the Transition Results and the close button$/) do
  page.driver.browser.switch_to.alert.accept
  expect(page).to have_content(/Market Transitions Added/i)
  expect(page).to have_content(/Close/i)
end

When(/^Hbx Admin clicks close button$/) do
  click_link 'Close'
end

Then(/^Transition family members form should be closed$/) do
  expect(page).not_to have_content(/Transition Family Members/i)
end

When(/^Hbx Admin clicks on continue button on Choose Coverage page$/) do
  click_button 'CONTINUE', :wait => 10
end