
Given (/a matched Employee exists with multiple employee roles/) do
  org1 = FactoryGirl.create :organization, :with_active_plan_year
  org2 = FactoryGirl.create :organization, :with_active_plan_year_and_without_dental
  benefit_group1 = org1.employer_profile.plan_years[0].benefit_groups[0]
  benefit_group2 = org2.employer_profile.plan_years[0].benefit_groups[0]
  bga1 = FactoryGirl.build :benefit_group_assignment, benefit_group: benefit_group1
  bga2 = FactoryGirl.build :benefit_group_assignment, benefit_group: benefit_group2
  FactoryGirl.create(:user)
  @person = FactoryGirl.create(:person, :with_family, first_name: "Employee", last_name: "E", user: user)
  employee_role1 = FactoryGirl.create :employee_role, person: @person, employer_profile: org1.employer_profile
  employee_role2 = FactoryGirl.create :employee_role, person: @person, employer_profile: org2.employer_profile
  ce1 =  FactoryGirl.create(:census_employee, 
          first_name: @person.first_name, 
          last_name: @person.last_name, 
          dob: @person.dob, 
          ssn: @person.ssn, 
          employee_role_id: employee_role1.id,
          employer_profile: org1.employer_profile
        )
  ce2 =  FactoryGirl.create(:census_employee, 
          first_name: @person.first_name, 
          last_name: @person.last_name, 
          dob: @person.dob, 
          ssn: @person.ssn, 
          employee_role_id: employee_role2.id,
          employer_profile: org2.employer_profile
        )

  ce1.benefit_group_assignments << bga1
  ce1.link_employee_role!

  ce2.benefit_group_assignments << bga2
  ce2.link_employee_role!

  employee_role1.update_attributes(census_employee_id: ce1.id, employer_profile_id: org1.employer_profile.id)
  employee_role2.update_attributes(census_employee_id: ce2.id, employer_profile_id: org2.employer_profile.id)
end


And(/(.*) has a dependent in (.*) relationship with age (.*) than 26/) do |role, kind, var|
  dob = (var == "greater" ? TimeKeeper.date_of_record - 35.years : TimeKeeper.date_of_record - 5.years)
  @family = Family.all.first
  if role == "consumer"
    dependent = FactoryGirl.create :person, :with_consumer_role, dob: dob
  else
    dependent = FactoryGirl.create :person, dob: dob
  end
  fm = FactoryGirl.create :family_member, family: @family, person: dependent
  user.person.person_relationships << PersonRelationship.new(kind: kind, relative_id: dependent.id)
  ch = @family.active_household.immediate_family_coverage_household
  ch.coverage_household_members << CoverageHouseholdMember.new(family_member_id: fm.id)
  ch.save
  user.person.save
end

And(/(.*) also has a health enrollment with primary person covered/) do |role|
  sep = FactoryGirl.create :special_enrollment_period, family: @family
  enrollment = FactoryGirl.create(:hbx_enrollment, 
                                  household: @family.active_household,
                                  kind: (@employee_role.present? ? "employer_sponsored" : "individual"),
                                  effective_on: TimeKeeper.date_of_record,
                                  enrollment_kind: "special_enrollment",
                                  special_enrollment_period_id: sep.id,
                                  employee_role_id: (@employee_role.id if @employee_role.present?),
                                  benefit_group_id: (@benefit_group.id if @benefit_group.present?)
                                )
  enrollment.hbx_enrollment_members << HbxEnrollmentMember.new(applicant_id: @family.primary_applicant.id,
    eligibility_date: TimeKeeper.date_of_record - 2.months,
    coverage_start_on: TimeKeeper.date_of_record - 2.months
  )
  enrollment.save!
end

And(/employee also has a (.*) enrollment with primary covered under (.*) employer/) do |coverage_kind, var|
  sep = FactoryGirl.create :special_enrollment_period, family: @person.primary_family
  benefit_group = if var == "first"
                    @person.active_employee_roles[0].employer_profile.plan_years[0].benefit_groups[0]
                  else
                    @person.active_employee_roles[1].employer_profile.plan_years[0].benefit_groups[0]
                  end
  enrollment = FactoryGirl.create(:hbx_enrollment, 
                                  household: @person.primary_family.active_household,
                                  kind: "employer_sponsored",
                                  effective_on: TimeKeeper.date_of_record,
                                  coverage_kind: coverage_kind,
                                  enrollment_kind: "special_enrollment",
                                  special_enrollment_period_id: sep.id,
                                  employee_role_id: (var == "first" ? @person.active_employee_roles[0].id : @person.active_employee_roles[1].id),
                                  benefit_group_id: benefit_group.id
                                )
  enrollment.hbx_enrollment_members << HbxEnrollmentMember.new(applicant_id: @person.primary_family.primary_applicant.id,
    eligibility_date: TimeKeeper.date_of_record - 2.months,
    coverage_start_on: TimeKeeper.date_of_record - 2.months
  )
  enrollment.save!
end

And(/(.*) should see the (.*) family member (.*) and (.*)/) do |employee, type, disabled, checked|
  if type == "ineligible"
    expect(find("#family_member_ids_1")).to be_disabled
    expect(find("#family_member_ids_1")).not_to be_checked
  else
    expect(find("#family_member_ids_0")).not_to be_disabled
    expect(find("#family_member_ids_0")).to be_checked
  end
end

And(/(.*) should also see the reason for ineligibility/) do |role|
  if role == "consumer"
    expect(page).to have_content "eligibility failed on family_relationships"
  else
    expect(page).to have_content "This dependent is ineligible for employer-sponsored coverage."
  end
end

And(/(.*) should see the dental radio button/) do |role|
  expect(page).to have_content "Dental"
end

And(/(.*) switched to dental benefits/) do |role|
  # choose("coverage_kind_dental")
  wait_for_ajax
  find(:xpath, '//*[@id="dental-radio-button"]/label').click
end

Then(/the primary person checkbox should be in unchecked status/) do
  expect(find("#family_member_ids_0")).not_to be_checked
end

Then(/(.*) should see both dependent and primary/) do |role|
  primary = Person.all.select { |person| person.primary_family.present? }.first
  expect(page).to have_content "COVERAGE FOR: #{primary.full_name} + 1 Dependent"
end

Then(/(.*) should only see the dependent name/) do |role|
  dependent = Person.all.select { |person| person.primary_family.blank? }.first
  expect(page).to have_content "COVERAGE FOR: #{dependent.full_name}"
end

Then(/(.*) should see primary person/) do |role|
  primary = Person.all.select { |person| person.primary_family.present? }.first
  expect(page).to have_content "COVERAGE FOR: #{primary.full_name}"
end

Then(/(.*) should see the enrollment with make changes button/) do |role|
  expect(page).to have_content "#{TimeKeeper.date_of_record.year} HEALTH COVERAGE"
  expect(page).to have_link "Make Changes"
end

Then(/(.*) should see the dental enrollment with make changes button/) do |role|
  expect(page).to have_content "#{TimeKeeper.date_of_record.year} DENTAL COVERAGE"
  expect(page).to have_link "Make Changes"
end

When(/(.*) clicked on make changes button/) do |role|
  click_link "Make Changes"
end

When(/(.*) clicked continue on household info page/) do |role|
  find_all("#btn_household_continue")[1].click
end

Then(/(.*) should see all the family members names/) do |role|
  people = Person.all
  people.each do |person|
    expect(page).to have_content "#{person.full_name}"
  end
end

When(/consumer (.*) the primary person/) do |checked|
  if checked == "checks"
    find("#family_member_ids_0").set(true)
  else
    find("#family_member_ids_0").set(false)
  end
end

And(/(.*) clicked on shop for new plan/) do |role|
  find(".interaction-click-control-shop-for-new-plan").click
end

And(/employee has a valid "(.*)" qle/) do |qle|
  qle = FactoryGirl.create :qualifying_life_event_kind, title: qle
end

And(/employee cannot uncheck primary person/) do
  expect(find("tr.is_primary td input")["onclick"]).to eq "return false;"
end

When(/employee (.*) the dependent/) do |checked|
  if checked == "checks"
    find("#family_member_ids_0").set(true)
  else
    find("#family_member_ids_1").set(false)
  end
end

And(/second ER not offers health benefits to spouse/) do
  benefit_group = @person.active_employee_roles[1].employer_profile.plan_years[0].benefit_groups[0]
  benefit_group.relationship_benefits.where(relationship: "spouse").first.update_attributes(offered: false)
  benefit_group.save
end

And(/first ER not offers dental benefits to spouse/) do
  benefit_group = @person.active_employee_roles[0].employer_profile.plan_years[0].benefit_groups[0]
  benefit_group.dental_relationship_benefits.where(relationship: "spouse").first.update_attributes(offered: false) rescue ""
  benefit_group.save
end

And(/employee should not see the reason for ineligibility/) do
  expect(page).not_to have_content "This dependent is ineligible for employer-sponsored coverage."
end

When(/employee switched to (.*) employer/) do |employer|
  if employer == "first"
    find(:xpath, '//*[@id="employer-selection"]/div/div[1]/label').click
  else
    find(:xpath, '//*[@id="employer-selection"]/div/div[2]/label').click
  end
end

And(/(.*) should not see the dental radio button/) do |role|
  expect(page).not_to have_content "Dental"
end

When(/employee clicked on make changes of health enrollment from first employer/) do
  find(:xpath, '//*[@id="account-detail"]/div[2]/div[1]/div[3]/div[3]/div/div[3]/div/span/a')
end

