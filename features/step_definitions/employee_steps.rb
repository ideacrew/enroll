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
    And I select the all security question and give the answer
    When I have submitted the security questions
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

