Given (/a matched Employee exists with only employee role/) do
  FactoryBot.create(:user)
  person = FactoryBot.create(:person, :with_employee_role, :with_family, first_name: "Employee", last_name: "E", user: user)
  org = FactoryBot.create :organization, :with_active_plan_year
  @benefit_group = org.employer_profile.plan_years[0].benefit_groups[0]
  bga = FactoryBot.build :benefit_group_assignment, benefit_group: @benefit_group
  @employee_role = person.employee_roles[0]
  ce =  FactoryBot.build(:census_employee,
          first_name: person.first_name,
          last_name: person.last_name,
          dob: person.dob,
          ssn: person.ssn,
          employee_role_id: @employee_role.id,
          employer_profile: org.employer_profile
        )

  ce.benefit_group_assignments << bga
  ce.link_employee_role!
  ce.save!
  @employee_role.update_attributes(census_employee_id: ce.id, employer_profile_id: org.employer_profile.id)
end

Given (/(.*) has a matched employee role/) do |name|
  steps %{
    When Patrick Doe creates an HBX account
    When Employee goes to register as an employee
    Then Employee should see the employee search page
    When Employee enters the identifying info of Patrick Doe
    Then Employee should see the matched employee record form
    When Employee accepts the matched employer
    When Employee completes the matched employee form for Patrick Doe
  }
end

def employee_by_legal_name(legal_name, person)
  org = org_by_legal_name(legal_name)
  employee_role = FactoryBot.create(:employee_role, person: person, benefit_sponsors_employer_profile_id: org.employer_profile.id)
  ce = FactoryBot.create(:census_employee,
    first_name: person.first_name,
    last_name: person.last_name,
    ssn: person.ssn,
    dob: person.dob,
    employer_profile: org.employer_profile,
    benefit_sponsorship: benefit_sponsorship(org),
    employee_role_id: employee_role.id
  )
end

Given (/a person exists with dual roles/) do
  FactoryBot.create(:user)
  FactoryBot.create(:person, :with_employee_role, :with_consumer_role, :with_family, first_name: "Dual Role Person", last_name: "E", user: user)
end

Then (/(.*) sign in to portal/) do |name|
  user = Person.where(first_name: "#{name}").first.user
  login_as user
  BenefitMarkets::Products::ProductRateCache.initialize_rate_cache!
  visit "/families/home"
end

And (/Employee should see a button to enroll in ivl market/) do
  expect(page).to have_content "Enroll in health or dental coverage on the District of Columbia's individual market"
  expect(page).to have_link "Enroll"
end

Then (/Dual Role Person should not see any button to enroll in ivl market/) do
  expect(page).not_to have_content "Enroll in health or dental coverage on the District of Columbia's individual market"
  expect(page).not_to have_link "Enroll"
end

And (/Employee clicks on Enroll/) do
  within ".shop-for-plans-widget" do
    click_link "Enroll"
  end
end

Then (/Employee redirects to ivl flow/) do
  expect(page).to have_content("Personal Information")
end

And(/employee (.*) with a dependent has (.*) relationship with age (.*) than 26/) do |named_person, kind, var|
  dob = (var == "greater" ? TimeKeeper.date_of_record - 35.years : TimeKeeper.date_of_record - 5.years)
  person_hash = people[named_person]
  person = Person.where(:first_name => /#{person_hash[:first_name]}/i,
                        :last_name => /#{person_hash[:last_name]}/i).first
  @family = person.primary_family
  dependent = FactoryBot.create :person, dob: dob
  fm = FactoryBot.create :family_member, family: @family, person: dependent
  person.person_relationships << PersonRelationship.new(kind: kind, relative_id: dependent.id)
  ch = @family.active_household.immediate_family_coverage_household
  ch.coverage_household_members << CoverageHouseholdMember.new(family_member_id: fm.id)
  ch.save
  person.save
end

When(/^.+ clicks initiate cobra$/) do
  click_link "Initiate cobra"
end

When(/^clicks cobra confirm$/) do
  terminated_date = TimeKeeper.date_of_record + 31.days
  find('.date-picker').set(terminated_date)
  find('.cobra_confirm').click
end

When(/^clicks terminated employees tab$/) do
  find('div', :text => 'Terminated', :class => 'btn-default').click
end

When(/^should see terminated employee$/) do
  wait_for_ajax
  expect(find_all('.col-employee_name').size).to eq(2)
end

When(/^.+ clicks sign in existing account$/) do
  click_link "Sign In Existing Account"
end

When /^should see log in form$/ do
  expect(page).to have_selector(:id, 'user_login')
end

When(/^Patrick Doe logs in$/) do
  person = people["Patrick Doe"]
  user = user_record_from_census_employee(person)
  login_as user
  visit "/"
  click_link 'Employee Portal'
end

When /^clicks on the employee profile for Patrick$/ do
  click_link "Patrick Doe"
  wait_for_ajax
end

Then /^.+ should see dependents including Patrick's wife$/ do
  wait_for_ajax
  expect(find_all('#dependent_info > div').count).to eq(1)
end

Then /^.+ should not see dependents$/ do
  wait_for_ajax
  expect(find_all('#dependent_info > div').count).to eq(0)
end

When /^Employer clicks on Actions button$/ do
  click_button "Actions"
end

When /^Employer clicks on terminate button for an employee$/ do
  click_link "Terminate"
  find('input.date-picker').set((TimeKeeper.date_of_record - 1.days).to_s)
  click_link "Terminate Employee"
end

When /^Employer clicks on future termination button for an employee$/ do
  click_link "Terminate"
  find('input.date-picker').set((TimeKeeper.date_of_record + 10.days).to_s)
  click_link "Terminate Employee"
end

When /^Employer clicks cobra tab$/ do
  find("div", class:"btn-default",text: "COBRA Only").click
end

When /^.+ enters? the spouse info of Patrick wife$/ do
  fill_in 'jq_datepicker_ignore_dependent[dob]', with: '01/15/1996'
  fill_in 'dependent[first_name]', with: 'Cynthia'
  fill_in 'dependent[last_name]', with: 'Patrick'
  fill_in 'dependent[ssn]', with: '123445678'
  find('h1', :text => 'Manage Family').click
  sleep 1
  find(:xpath, "//span[@class='label'][contains(., 'This Person Is')]").click
  find(:xpath, "//li[@data-index='1'][contains(., 'Spouse')]").click
  find(:xpath, "//label[@for='radio_female']").click
  fill_in 'dependent[addresses][0][address_1]', with: '123 STREET'
  fill_in 'dependent[addresses][0][city]', with: 'WASHINGTON'
  find(:xpath, "//span[@class='label'][contains(., 'SELECT STATE')]").click
  find(:xpath, "//li[@data-index='24'][contains(., 'MA')]").click
  fill_in 'dependent[addresses][0][zip]', with: '01001'
end

When /^.+ enters? the spouse info of Patrick's wife without address$/ do
  fill_in 'jq_datepicker_ignore_dependent[dob]', with: '01/15/1996'
  fill_in 'dependent[first_name]', with: 'Cynthia'
  fill_in 'dependent[last_name]', with: 'Patrick'
  fill_in 'dependent[ssn]', with: '123445678'
  find('h1', :text => 'Manage Family').click
  sleep 1
  find(:xpath, "//span[@class='label'][contains(., 'This Person Is')]").click
  find(:xpath, "//li[@data-index='1'][contains(., 'Spouse')]").click
  find(:xpath, "//label[@for='radio_female']").click
end

When /^.+ enters? the parent info of Patrick father$/ do
  fill_in 'jq_datepicker_ignore_dependent[dob]', with: '01/15/1996'
  fill_in 'dependent[first_name]', with: 'George'
  fill_in 'dependent[last_name]', with: 'Patrick'
  fill_in 'dependent[ssn]', with: '101505808'
  find('h1', :text => 'Manage Family').click
  sleep 1
  find(:xpath, "//span[@class='label'][contains(., 'This Person Is')]").click
  find(:xpath, "//li[@data-index='4'][contains(., 'Parent')]").click
  find(:xpath, "//label[@for='radio_male']").click
  fill_in 'dependent[addresses][0][address_1]', with: '123 STREET'
  fill_in 'dependent[addresses][0][city]', with: 'WASHINGTON'
  find(:xpath, "//span[@class='label'][contains(., 'SELECT STATE')]").click
  find(:xpath, "//li[@data-index='24'][contains(., 'MA')]").click
  fill_in 'dependent[addresses][0][zip]', with: '01001'
end

When /^.+ continues to Plan Shopping$/ do
  find('.btn', text: "CONTINUE", wait: 5).click
  wait_for_ajax
  find('.btn', text: "CONTINUE", wait: 5).click
  wait_for_ajax
end

And(/(.*) shops for the second sponsored plan/) do |role|
  find(".interaction-click-control-shop-for-plans", wait: 5).click
  find_all("#employer-selection label").last.click
  find('.interaction-click-control-shop-for-new-plan').click
  find('.plan-select', match: :first).click
end

When /^visits My Insured Portal$/ do
  visit "/families/home?tab=home"
end

When /^(.*) visits Returning User Portal$/ do |named_person|
  click_link "Returning User"
  person = people[named_person]
  census_employee = CensusEmployee.find_by(first_name: person[:first_name], last_name: person[:last_name])
  user = user_record_from_census_employee(census_employee)
  login_as user
end
