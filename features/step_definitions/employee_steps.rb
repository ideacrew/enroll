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
  person.ensure_relationship_with(dependent, kind)
  ch = @family.active_household.immediate_family_coverage_household
  ch.coverage_household_members << CoverageHouseholdMember.new(family_member_id: fm.id)
  ch.save
  person.save
end

Given(/^Covid QLE present with top ordinal position$/) do
  FactoryBot.create(:qualifying_life_event_kind, title: 'Covid-19', reason: 'covid-19', market_kind: "shop", post_event_sep_in_days: 30,  effective_on_kinds: ["first_of_this_month", "fixed_first_of_next_month"], ordinal_position: 5, qle_event_date_kind: :submitted_at)
end

Then(/^Employee should see the "(.*?)" at the top of the shop qle list$/) do |qle_event|
  expect(find('.qles-panel #carousel-qles .item.active').find_all('p.no-op')[0]).to have_content(qle_event)
end

And(/Employee should see today date and clicks continue/) do
  screenshot("current_qle_date")
  
  expect(find('#qle_date').value).to eq TimeKeeper.date_of_record.strftime("%m/%d/%Y")
  expect(find('#qle_date')['readonly']).to eq 'true'
  expect(find('input#qle_date', style: {'pointer-events': 'none'})).to be_truthy

  within '#qle-date-chose' do
    find('.interaction-click-control-continue').click
  end
end

And(/Employee select "(.*?)" for "(.*?)" sep effective on kind and clicks continue/) do |effective_on_kind, qle_reason|
  expect(page).to have_content "Based on the information you entered, you may be eligible to enroll now but there is limited time"

  if qle_reason == 'covid-19'
    qle_on = TimeKeeper.date_of_record
    
    effective_on_kind_date = case effective_on_kind
    when 'fixed_first_of_next_month'
      qle_on.end_of_month.next_day.to_s
    when 'first_of_this_month'
      qle_on.beginning_of_month.to_s
    end

    select effective_on_kind_date, from: 'effective_on_kind'
  else
    select effective_on_kind.humanize, from: 'effective_on_kind'
  end
  click_button "Continue"
end

Then(/Employee should see the group selection page with "(.*?)" effective date/) do |effective_on_kind|

  effective_on = case effective_on_kind
  when "first_of_this_month"
    TimeKeeper.date_of_record.beginning_of_month
  when "fixed_first_of_next_month"
    TimeKeeper.date_of_record.end_of_month + 1.day
  end

  expect(find('#effective_date')).to have_content("EFFECTIVE DATE: #{effective_on.strftime("%m/%d/%Y")}")
end

Then(/Employee should see (.*?) page with "(.*?)" as coverage effective date/) do |screen, effective_on_kind|
  
  effective_on = case effective_on_kind
  when "first_of_this_month"
    TimeKeeper.date_of_record.beginning_of_month
  when "fixed_first_of_next_month"
    TimeKeeper.date_of_record.end_of_month + 1.day
  end

  find('.coverage_effective_date', text: effective_on.strftime("%m/%d/%Y"), wait: 5)

  if screen == "coverage summary"
    find('.interaction-click-control-confirm').click
  else
    find('.interaction-click-control-go-to-my-account').click
  end
end
