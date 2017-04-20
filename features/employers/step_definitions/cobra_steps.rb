def people_for_cobra
  return @a if defined?(@a)
  @a = {
    "Jack Cobra" => {
      first_name: "Jack",
      last_name: "Cobra",
      dob: "08/10/1960",
      ssn: "196008107",
      email: "jack@cobra.com",
      password: 'aA1!aA1!aA1!'
    },
    "Jack Employee" => {
      first_name: "Jack",
      last_name: "Employee",
      dob: "08/10/1960",
      ssn: "196008111",
      email: "jack@employee.com",
      password: 'aA1!aA1!aA1!'
    },
    "Jack Doe" => {
      first_name: "Jack",
      last_name: "Doe",
      dob: '10/11/1978',
      legal_name: "BestLife",
      dba: "BestLife",
      fein: "050000000",
      ssn: "197810118",
      email: "jack@dc.gov",
      password: 'aA1!aA1!aA1!'
    },
  }
end

When(/^(.*) create a new account for employer$/) do |named_person|
  person = people_for_cobra[named_person]
  fill_in "user[oim_id]", :with => person[:email]
  fill_in "user[password]", :with => person[:password]
  fill_in "user[password_confirmation]", :with => person[:password]
  screenshot("create_account")
  find(".interaction-click-control-create-account").click
end

Then(/^Employer should see a form to enter information about employee, address and dependents details for Jack Cobra$/) do
  person = people_for_cobra['Jack Cobra']
  # Census Employee
  fill_in 'census_employee[first_name]', with: person[:first_name]
  fill_in 'census_employee[last_name]', with: person[:last_name]
  find(:xpath, "//p[contains(., 'NONE')]").click
  find(:xpath, "//li[contains(., 'Jr.')]").click

  fill_in 'jq_datepicker_ignore_census_employee[dob]', :with => person[:dob]
  fill_in 'census_employee[ssn]', :with => person[:ssn]

  find(:xpath, "//label[@for='census_employee_gender_male']").click

  fill_in 'jq_datepicker_ignore_census_employee[hired_on]', :with => (TimeKeeper.date_of_record - 10.days).to_s

  find(:xpath, "//div[div/select[@name='census_employee[benefit_group_assignments_attributes][0][benefit_group_id]']]//p[@class='label']").click
  find(:xpath, "//div[div/select[@name='census_employee[benefit_group_assignments_attributes][0][benefit_group_id]']]//li[@data-index='1']").click

  # cobra
  find('input#census_employee_existing_cobra').click
  fill_in 'jq_datepicker_ignore_census_employee[cobra_begin_date]', with: (TimeKeeper.date_of_record - 5.days).to_s

  # Address
  fill_in 'census_employee[address_attributes][address_1]', :with => "1026 Potomac"
  fill_in 'census_employee[address_attributes][address_2]', :with => "Apt ABC"
  fill_in 'census_employee[address_attributes][city]', :with => "Alpharetta"

  find(:xpath, "//p[@class='label'][contains(., 'SELECT STATE')]").click
  find(:xpath, "//li[contains(., 'GA')]").click

  fill_in 'census_employee[address_attributes][zip]', :with => "30228"

  find(:xpath, "//p[contains(., 'SELECT KIND')]").click
  find(:xpath, "//li[@data-index='1'][contains(., 'home')]").click

  fill_in 'census_employee[email_attributes][address]', :with => person[:email]

  screenshot("create_census_employee_with_data")
  click_button "Create Employee"
end

Then(/^Employer should see a form to enter information about employee, address and dependents details for Jack Employee$/) do
  person = people_for_cobra['Jack Employee']
  # Census Employee
  fill_in 'census_employee[first_name]', with: person[:first_name]
  fill_in 'census_employee[last_name]', with: person[:last_name]
  find(:xpath, "//p[contains(., 'NONE')]").click
  find(:xpath, "//li[contains(., 'Jr.')]").click

  fill_in 'jq_datepicker_ignore_census_employee[dob]', :with => person[:dob]
  fill_in 'census_employee[ssn]', :with => person[:ssn]

  find(:xpath, "//label[@for='census_employee_gender_male']").click

  fill_in 'jq_datepicker_ignore_census_employee[hired_on]', :with => (TimeKeeper.date_of_record - 10.days).to_s

  find(:xpath, "//div[div/select[@name='census_employee[benefit_group_assignments_attributes][0][benefit_group_id]']]//p[@class='label']").click
  find(:xpath, "//div[div/select[@name='census_employee[benefit_group_assignments_attributes][0][benefit_group_id]']]//li[@data-index='1']").click

  # Address
  fill_in 'census_employee[address_attributes][address_1]', :with => "1026 Potomac"
  fill_in 'census_employee[address_attributes][address_2]', :with => "Apt ABC"
  fill_in 'census_employee[address_attributes][city]', :with => "Alpharetta"

  find(:xpath, "//p[@class='label'][contains(., 'SELECT STATE')]").click
  find(:xpath, "//li[contains(., 'GA')]").click

  fill_in 'census_employee[address_attributes][zip]', :with => "30228"

  find(:xpath, "//p[contains(., 'SELECT KIND')]").click
  find(:xpath, "//li[@data-index='1'][contains(., 'home')]").click

  fill_in 'census_employee[email_attributes][address]', :with => person[:email]

  screenshot("create_census_employee_with_data")
  click_button "Create Employee"
end

Then(/^fill the form with hired date as future date$/) do
  person = people_for_cobra['Jack Employee']
  # Census Employee
  fill_in 'census_employee[first_name]', with: person[:first_name]
  fill_in 'census_employee[last_name]', with: person[:last_name]
  find(:xpath, "//p[contains(., 'NONE')]").click
  find(:xpath, "//li[contains(., 'Jr.')]").click

  fill_in 'jq_datepicker_ignore_census_employee[dob]', :with => person[:dob]
  fill_in 'census_employee[ssn]', :with => person[:ssn]

  find(:xpath, "//label[@for='census_employee_gender_male']").click

  fill_in 'jq_datepicker_ignore_census_employee[hired_on]', :with => (TimeKeeper.date_of_record + 1.days).to_s

  # Address
  fill_in 'census_employee[address_attributes][address_1]', :with => "1026 Potomac"
  fill_in 'census_employee[address_attributes][address_2]', :with => "Apt ABC"
  fill_in 'census_employee[address_attributes][city]', :with => "Alpharetta"

  find(:xpath, "//p[@class='label'][contains(., 'SELECT STATE')]").click
  find(:xpath, "//li[contains(., 'GA')]").click

  fill_in 'census_employee[address_attributes][zip]', :with => "30228"

  find(:xpath, "//p[contains(., 'SELECT KIND')]").click
  find(:xpath, "//li[@data-index='1'][contains(., 'home')]").click

  fill_in 'census_employee[email_attributes][address]', :with => person[:email]

  click_button "Create Employee"
end

And(/^.+ should see census employee created success message for (.*)$/) do |named_person|
  person = people_for_cobra[named_person]
  expect(page).to have_content('Census Employee is successfully created.')
  screenshot("employer_census_new_family_success_message")
  expect(page).to have_content(person[:first_name])
  expect(page).to have_content(person[:last_name])
end

Then(/employer should see the message Your employee was successfully added to your roster on page/) do
  expect(page).to have_content('Your employee was successfully added to your roster')
  person = people_for_cobra['Jack Employee']
  expect(page).to have_content(person[:first_name])
  expect(page).to have_content(person[:last_name])  
  expect(page).to have_content((TimeKeeper.date_of_record + 1.days).to_s)
end

And(/^.+ should see the status of cobra_eligible$/) do
  expect(page).to have_content('Cobra Eligible')
end

And(/^.+ should see the status of Cobra Linked$/) do
  expect(page).to have_content('Cobra Linked')
end

And(/^.+ should see the status of Employee Role Linked$/) do
  expect(page).to have_content('Employee Role Linked')
end

And(/^.+ should see the status of eligible$/) do
  expect(page).to have_content('Eligible')
end

Then(/^Jack Cobra should see the receipt page and verify employer contribution for cobra employee$/) do
  expect(page).to have_content('Enrollment Submitted')
  expect(page).to have_content('Market: Employer Sponsored COBRA/Continuation')
  expect(page).to have_content('Your employer may charge an additional administration fee for your COBRA/Continuation coverage. If you have any questions, please direct them to the Employer.')
  expect(page).to have_content('$0.00')
  screenshot("receipt_page_for_cobra_employee")
  find('.interaction-click-control-continue').click
end

Then(/^Jack Employee should see the receipt page and verify employer contribution for normal employee$/) do
  expect(page).to have_content('Enrollment Submitted')
  expect(page).to have_content('Market: Employer Sponsored')
  expect(page).not_to have_content('Your employer may charge an additional administration fee for your COBRA/Continuation coverage. If you have any questions, please direct them to the Employer.')
  screenshot("receipt_page_for_normal_employee")
  find('.interaction-click-control-continue').click
end

Then(/^.+ should see my account page$/) do
  expect(page).to have_content('My DC Health Link')
  expect(page).to have_content('My Account')
end

When(/^(.*) login in for (.*)$/) do |named_person, role|
  person = people_for_cobra[named_person]
  email_address = person[:email]
  password = person[:password]

  click_link "Sign In Existing Account"
  expect(page).to have_content('Sign In')

  fill_in "user[login]", with: email_address
  find('#user_login').set(email_address)
  fill_in "user[password]", with: password
  fill_in "user[login]", :with => email_address unless find(:xpath, '//*[@id="user_login"]').value == email_address
  find('.interaction-click-control-sign-in').click
end

Then(/^(.*) should see employer profile page$/) do |named_person|
  person = people_for_cobra[named_person]
  expect(page).to have_content('My Health Benefits Program')
  expect(page).to have_content(person[:legal_name])
end

When(/Set Date two months later/) do
  TimeKeeper.set_date_of_record_unprotected!(TimeKeeper.date_of_record + 2.months)
end

Then(/Set Date back to two months ago/) do
  TimeKeeper.set_date_of_record_unprotected!(TimeKeeper.date_of_record - 2.months)
end

When(/^.+ terminate one employee$/) do
  find('tr.even i.fa-trash-o').click
  find('input.date-picker').set((TimeKeeper.date_of_record - 1.days).to_s)
  find('.employees-section').click
  click_link 'Terminate Employee'
  wait_for_ajax(5)
end

Then(/^.+ should see terminate successful msg$/) do
  expect(page).to have_content('Successfully terminated Census Employee.')
end

When(/^.+ click all employee filter$/) do
  find('.filter').click
  find('input#family_all').trigger('click')
end

Then(/^.+ should see the status of Employment terminated$/) do
  expect(page).to have_content('Employment Terminated')
end

When(/^.+ cobra one employee$/) do
  find('a.show_cobra_confirm').click
  find('a.cobra_confirm_submit').click
end

Then(/^.+ should see cobra successful msg/) do
  expect(page).to have_content('Successfully update Census Employee.')
end

And(/^.+ should only see the status of Cobra Linked$/) do
  expect(page).to have_content('Cobra Linked')
  expect(page).not_to have_content('Employee Role Linked')
  expect(page).not_to have_content('Employment Terminated')
end

Then(/^.+ should see cobra enrollment on my account page/) do
  expect(page).to have_content('Terminated')
  unless TimeKeeper.date_of_record.day == 1
    expect(page).to have_content('Coverage Selected')
  else
    expect(page).to have_content('Coverage Enrolled')
  end
end

Then(/^.+ should see market type on my account page/) do
  expect(page).to have_content("Market Type: Employer Sponsored COBRA/Continuation")
end

Then(/^.+ should not see individual on enrollment title/) do
  expect(page).not_to have_content("Individual & Family")
end

And(/^.+ should be able to enter plan year, benefits, relationship benefits for cobra$/) do
  find(:xpath, "//p[@class='label'][contains(., 'SELECT START ON')]").click
  find(:xpath, "//li[@data-index='1'][contains(., '#{(Date.today + 2.months).year}')]").click

  screenshot("employer_add_plan_year")
  find('.interaction-field-control-plan-year-fte-count').click

  fill_in "plan_year[fte_count]", :with => "35"
  fill_in "plan_year[pte_count]", :with => "15"
  fill_in "plan_year[msp_count]", :with => "3"

  find('.interaction-click-control-continue').click

  # Benefit Group
  fill_in "plan_year[benefit_groups_attributes][0][title]", :with => "Silver PPO Group"

  find('.interaction-choice-control-plan-year-start-on').click
  find('li.interaction-choice-control-plan-year-start-on-1').click

  fill_in "plan_year[benefit_groups_attributes][0][relationship_benefits_attributes][0][premium_pct]", :with => 50
  fill_in "plan_year[benefit_groups_attributes][0][relationship_benefits_attributes][1][premium_pct]", :with => 50
  fill_in "plan_year[benefit_groups_attributes][0][relationship_benefits_attributes][2][premium_pct]", :with => 50
  fill_in "plan_year[benefit_groups_attributes][0][relationship_benefits_attributes][3][premium_pct]", :with => 50

  find(:xpath, '//li/label[@for="plan_year_benefit_groups_attributes_0_plan_option_kind_single_carrier"]').click
  wait_for_ajax
  find('.carriers-tab a').click
  wait_for_ajax
  find('.reference-plans label').click
  wait_for_ajax
  find('.interaction-click-control-create-plan-year').trigger('click')
end

And(/clicks on the Add New Employee button/) do
  find('.interaction-click-control-add-new-employee').click
end
