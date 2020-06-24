module CensusEmployeeWorld
  def census_employees(roster_count = 1, *traits)
    attributes = traits.extract_options!
    @census_employees ||= FactoryBot.create_list(:census_employee, roster_count, attributes)
  end

  def fetch_benefit_group(legal_name)
    employer(legal_name).benefit_sponsorships.first.benefit_applications.first.benefit_packages.first
  end

  def build_enrollment(attributes, *traits)
    @hbx_enrollment ||= FactoryBot.create(
      :hbx_enrollment, 
      :with_enrollment_members,
      *traits,
      family: attributes[:family],
      household: attributes[:household],
      benefit_group_assignment: attributes[:benefit_group_assignment],
      employee_role: attributes[:employee_role],
      rating_area_id: attributes[:rating_area_id],
      sponsored_benefit_id: attributes[:sponsored_benefit_id],
      sponsored_benefit_package_id: attributes[:sponsored_benefit_package_id]
    )
  end

  def person_record_from_census_employee(person, legal_name = nil, organizations = nil)
    organizations.reject! { |organization| @organization.values.include?(organization) == false }
    census_employee = CensusEmployee.where(first_name: person[:first_name], last_name: person[:last_name]).first
    
    employer_prof = employer_profile(legal_name)
    emp_staff_role = FactoryBot.create(
      :benefit_sponsor_employer_staff_role,
      aasm_state: 'is_active',
      benefit_sponsor_employer_profile_id: employer_prof.id
    )
    if Person.where(first_name: person[:first_name], last_name: person[:last_name]).present?
      person_record = Person.where(first_name: person[:first_name], last_name: person[:last_name]).first
      person_record.employer_staff_roles << emp_staff_role
      person_record.save
    else
      person_record = FactoryBot.build(
        :person_with_employee_role,
        :with_family,
        first_name: person[:first_name],
        last_name: person[:last_name],
        ssn: person[:ssn],
        dob: person[:dob_date],
        census_employee_id: census_employee.id,
        employer_profile_id: employer_prof.id,
        employer_staff_roles:[emp_staff_role],
        hired_on: census_employee.hired_on
      )
    end
    if organizations.present?
      emp_staff_roles = []
      organizations.each do |organization|
        employer_prof = employer.profiles.first
        emp_staff_role = FactoryBot.create(
          :benefit_sponsor_employer_staff_role,
          aasm_state: 'is_active',
          benefit_sponsor_employer_profile_id: employer_prof.id
        )
        emp_staff_roles << emp_staff_role
      end
      person_record.employer_staff_roles = emp_staff_roles
      person_record.save!
    else
      person_record.save!
    end
    person_record
  end

  def user_record_from_census_employee(person)
    person_record = Person.where(first_name: person[:first_name], last_name: person[:last_name]).first
    @person_user_record ||= FactoryBot.create(:user, :person => person_record)
  end

  def employee(employer=nil)
    if @employee
      @employee
    else
      employer_staff_role = FactoryBot.build(:benefit_sponsor_employer_staff_role, aasm_state: 'is_active', benefit_sponsor_employer_profile_id: employer.profiles.first.id)
      person = FactoryBot.create(:person, employer_staff_roles:[employer_staff_role])
      @employee = FactoryBot.create(:user, :person => person)
    end
  end

  def census_employee(named_person = nil)
    @census_employee ||= {}

    if named_person.present?
      @census_employee[named_person]
    else
      @census_employee.values.first
    end
  end

  def create_census_employee_from_person(named_person, legal_name = nil)
    person = people[named_person]
    organization = employer(legal_name)
    sponsorship = benefit_sponsorship(organization)
    benefit_group = fetch_benefit_group(organization.legal_name)
    @census_employee ||= {}
    # A broker employee may not have ssn when initially created through UI
    if person[:broker_census_employee]
      @census_employee[named_person] ||= FactoryBot.create(
        :census_employee,
        :with_active_assignment,
        first_name: person[:first_name],
        last_name: person[:last_name],
        dob: person[:dob_date],
        benefit_sponsorship: sponsorship,
        employer_profile: organization.profiles.first,
        benefit_group: benefit_group
      )
    else
      @census_employee[named_person] ||= FactoryBot.create(
        :census_employee,
        :with_active_assignment,
        first_name: person[:first_name],
        last_name: person[:last_name],
        dob: person[:dob_date],
        ssn: person[:ssn],
        benefit_sponsorship: sponsorship,
        employer_profile: organization.profiles.first,
        benefit_group: benefit_group
      )
    end
  end

  def census_employee_from_person(person)
    CensusEmployee.where(first_name: person[:first_name], last_name: person[:last_name]).first
  end
end

World(CensusEmployeeWorld)

And(/^census employee (.*?) new_hire_enrollment_period is greater than date of record$/) do |named_person|
  person = people[named_person]
  ce = CensusEmployee.where(:first_name => /#{person[:first_name]}/i, :last_name => /#{person[:last_name]}/i).first
  ce.update_attributes(hired_on: TimeKeeper.date_of_record + 1.month)
end

And(/^there (are|is) (\d+) (employee|employees) for (.*?)$/) do |_, roster_count, _, legal_name|
  sponsorship = employer(legal_name).benefit_sponsorships.first
  census_employees roster_count.to_i, benefit_sponsorship: sponsorship, employer_profile: sponsorship.profile
end

And(/^there is a census employee record for (.*?) for employer (.*?)$/) do |named_person, legal_name|
  create_census_employee_from_person(named_person, legal_name)
end

And(/^there is a census employee record and employee role for (.*?) for employer (.*?)$/) do |named_person, legal_name|
  create_census_employee_from_person(named_person, legal_name)
  person = people[named_person]
  organization = employer(legal_name)
  person_record = Person.where(first_name: person[:first_name], last_name: person[:last_name]).first
  employer_profile = employer_profile(legal_name)
  employer_staff_role = FactoryBot.build(:benefit_sponsor_employer_staff_role, aasm_state: 'is_active', benefit_sponsor_employer_profile_id: employer_profile.id)
  person_record.employee_roles <<  employer_staff_role
  person_record.save!
end

And(/^census employee (.*?) is a (.*) employee$/) do |named_person, state|
  person = people[named_person]
  census_employee.update(aasm_state: state)
end

Given(/^there exists (.*?) employee for employer (.*?)(?: and (.*?))?$/) do |named_person, legal_name, legal_name2|
  person = people[named_person]
  sponsorship =  employer(legal_name).benefit_sponsorships.first
  census_employees 1,
                   benefit_sponsorship: sponsorship, employer_profile: sponsorship.profile,
                   first_name: person[:first_name],
                   last_name: person[:last_name],
                   ssn: person[:ssn],
                   dob: person[:dob],
                   email: FactoryBot.build(:email, address: person[:email])
  if legal_name2.present?
    sponsorship2 = employer(legal_name2).benefit_sponsorships.first
    FactoryBot.create_list(:census_employee, 1,
                            benefit_sponsorship: sponsorship2,
                            employer_profile: sponsorship2.profile,
                            first_name: person[:first_name],
                            last_name: person[:last_name],
                            ssn: person[:ssn],
                            dob: person[:dob],
                            email: FactoryBot.build(:email, address: person[:email]))
  end
end

And(/employee (.*?) has (.*?) hired on date/) do |named_person, ee_hire_date|
  date = ee_hire_date == "current" ? TimeKeeper.date_of_record : TimeKeeper.date_of_record - 1.year
  person = people[named_person]
  CensusEmployee.where(:first_name => /#{person[:first_name]}/i,
                       :last_name => /#{person[:last_name]}/i).first.update_attributes(:hired_on => date, :created_at => date)
end

And(/employee (.*) has earliest eligible date under current active plan year/) do |named_person|
  census_employee = census_employee(named_person)
  sponsorship = census_employee.benefit_sponsorship
  renewal_application = sponsorship.renewal_benefit_application
  expect(census_employee.earliest_eligible_date < renewal_application.start_on).to be_truthy
end

And(/employee (.*) should see renewing benefit application start date as effective date/) do |named_person|
  census_employee = census_employee(named_person)
  sponsorship = census_employee.benefit_sponsorship
  renewal_application = sponsorship.renewal_benefit_application

  find('#group-selection-form', wait: 5, text: renewal_application.start_on.strftime('%m/%d/%Y'))
end

And(/employee (.*) already matched with employer (.*?)(?: and (.*?))? and logged into employee portal/) do |named_person, legal_name, legal_name2|
  person = people[named_person]
  sponsorship = employer(legal_name).benefit_sponsorships.first
  profile = sponsorship.profile
  ce = sponsorship.census_employees.where(:first_name => /#{person[:first_name]}/i,
                                          :last_name => /#{person[:last_name]}/i).first
  person_record = FactoryBot.create(:person_with_employee_role,
                                     first_name: person[:first_name],
                                     last_name: person[:last_name],
                                     ssn: person[:ssn],
                                     dob: person[:dob] || person[:dob_date],
                                     census_employee_id: ce.id,
                                     benefit_sponsors_employer_profile_id: profile.id,
                                     hired_on: ce.hired_on)

  sponsorship.benefit_applications.each do |benefit_application|
    benefit_application.benefit_packages.each{|benefit_package| ce.add_benefit_group_assignment(benefit_package) }
  end
  ce.update_attributes(employee_role_id: person_record.employee_roles.first.id)
  FactoryBot.create :family, :with_primary_family_member, person: person_record
  user = FactoryBot.create(:user,
                            person: person_record,
                            email: person[:email],
                            password: person[:password],
                            password_confirmation: person[:password])
  if legal_name2.present?
    sponsorship2 = org_by_legal_name(legal_name2).benefit_sponsorships.first
    profile2 = sponsorship2.profile
    ce1 = CensusEmployee.where(:first_name => /#{person[:first_name]}/i,
                               :last_name => /#{person[:last_name]}/i, benefit_sponsorship_id: sponsorship2.id).first
    employee_role = FactoryBot.create(:employee_role, person: person_record, benefit_sponsors_employer_profile_id: profile2.id, census_employee_id: ce1.id)
    ce1.update_attributes(employee_role_id: employee_role.id)
  end
  login_as user
  visit "/families/home"
end

And(/(.*) has active coverage and passive renewal/) do |named_person|
  person = people[named_person]
  ce = CensusEmployee.where(:first_name => /#{person[:first_name]}/i, :last_name => /#{person[:last_name]}/i).first
  person_rec = Person.where(first_name: /#{person[:first_name]}/i, last_name: /#{person[:last_name]}/i).first
  benefit_package = ce.active_benefit_group_assignment.benefit_package
  active_enrollment = FactoryBot.create(:hbx_enrollment,
                                         family: person_rec.primary_family,
                                         household: person_rec.primary_family.active_household,
                                         coverage_kind: "health",
                                         effective_on: benefit_package.start_on,
                                         enrollment_kind: "open_enrollment",
                                         kind: "employer_sponsored",
                                         submitted_at: benefit_package.start_on - 20.days,
                                         employee_role_id: person_rec.active_employee_roles.first.id,
                                         benefit_group_assignment_id: ce.active_benefit_group_assignment.id,
                                         benefit_sponsorship_id: ce.benefit_sponsorship.id,
                                         sponsored_benefit_package_id: benefit_package.id,
                                         sponsored_benefit_id: benefit_package.health_sponsored_benefit.id,
                                         rating_area_id: benefit_package.rating_area.id,
                                         product_id: benefit_package.health_sponsored_benefit.products(benefit_package.start_on).first.id,
                                         issuer_profile_id: benefit_package.health_sponsored_benefit.products(benefit_package.start_on).first.issuer_profile.id)
  new_benefit_package = benefit_sponsorship.renewal_benefit_application.benefit_packages.first
  active_enrollment.renew_benefit(new_benefit_package)
end

And(/^Employees for (.*?) have both Benefit Group Assignments Employee role$/) do |legal_name|
  #make it more generic by name

  step "Assign benefit group assignments to #{legal_name} employee"

  employer_profile = employer(legal_name).employer_profile

  @census_employees.each do |employee|
    person = FactoryBot.create(:person, :with_family, first_name: employee.first_name, last_name: employee.last_name, dob: employee.dob, ssn: employee.ssn)
    employee_role = FactoryBot.create(:employee_role, person: person, benefit_sponsors_employer_profile_id: employer_profile.id)
    employee.update_attributes(employee_role_id: employee_role.id)
  end
end

And(/^Assign benefit group assignments to (.*?) employee$/) do |legal_name|
  # try to fetch it from benefit application world
  benefit_package = fetch_benefit_group(legal_name)
  @census_employees.each do |employee|
    employee.add_benefit_group_assignment(benefit_package)
  end
end

And(/^employees for (.*?) have a selected coverage$/) do |legal_name|

  step "Employees for #{legal_name} have both Benefit Group Assignments Employee role"

  person = @census_employees.first.employee_role.person
  @census_employees.first.employee_role.update_attributes(census_employee_id: @census_employees.first.id)
  bga =  @census_employees.first.active_benefit_group_assignment
  benefit_package = fetch_benefit_group(legal_name)
  coverage_household = person.primary_family.households.first
  rating_area_id =  benefit_package.benefit_application.recorded_rating_area_id
  sponsored_benefit_id = benefit_package.sponsored_benefits.first.id
  build_enrollment({household: coverage_household,
                    benefit_group_assignment: bga,
                    family:person.primary_family,
                    employee_role: @census_employees.first.employee_role,
                    sponsored_benefit_package_id: benefit_package.id,
                    rating_area_id: rating_area_id,
                    sponsored_benefit_id: sponsored_benefit_id}, :with_health_product)
end

And(/^employer (.*?) with employee (.*?) is under open enrollment$/) do |legal_name, named_person|
  person = people[named_person]
  person_record = person_record_from_census_employee(person)
  user_record_from_census_employee(person)
  # we should not fetch like this
  census_employee = CensusEmployee.first
  bga =  census_employee.active_benefit_group_assignment
  benefit_package = fetch_benefit_group(legal_name)
  rating_area_id =  benefit_package.benefit_application.recorded_rating_area_id
  coverage_household = @person_family_record.households.first
  sponsored_benefit_id = benefit_package.sponsored_benefits.first.id

  build_enrollment({household: coverage_household,
                    benefit_group_assignment: bga,
                    family: @person_family_record,
                    employee_role: @census_employees.first.employee_role,
                    sponsored_benefit_package_id: benefit_package.id,
                    rating_area_id: rating_area_id,
                    sponsored_benefit_id: sponsored_benefit_id})
end

And(/^employer (.*?) with employee (.*?) has hbx_enrollment with health product$/) do |legal_name, named_person|
  person = people[named_person]
  person_record = create_person_and_user_from_census_employee(person)
  census_employee = CensusEmployee.where(first_name: person[:first_name], last_name: person[:last_name]).first
  bga =  census_employee.active_benefit_group_assignment
  benefit_package = fetch_benefit_group(legal_name)
  rating_area_id =  benefit_package.benefit_application.recorded_rating_area_id
  coverage_household = person_record.families.first.households.first
  sponsored_benefit_id = benefit_package.sponsored_benefits.first.id
  build_enrollment({household: coverage_household,
                    benefit_group_assignment: bga,
                    family: person_record.families.first,
                    employee_role: @census_employees.first.employee_role,
                    sponsored_benefit_package_id: benefit_package.id,
                    rating_area_id: rating_area_id,
                    sponsored_benefit_id: sponsored_benefit_id}, :with_health_product)
end

And(/^employer (.*?) with employee (.*?) has has person and user record present$/) do |legal_name, named_person|
  person = people[named_person]
  person_record = person_record_from_census_employee(person)
  user_record = user_record_from_census_employee(person)
end

And(/^employer (.*?) with employee (.*?) has (.*?) hbx_enrollment with health product$/) do |legal_name, named_person, enrollment_type|
  person = people[named_person]
  person_record = person_record_from_census_employee(person)
  user_record = user_record_from_census_employee(person)
  census_employee = CensusEmployee.where(first_name: person[:first_name], last_name: person[:last_name]).first
  attributes = {}
  attributes[:household] = person_record.families.first.households.first
  attributes[:family]  = person_record.families.first
  attributes[:benefit_group_assignment] = census_employee.active_benefit_group_assignment
  attributes[:employee_role] = @employer_staff_role #census_employee.employee_role
  # Will return the proper package if optional enrollment type arugmenet is set
  benefit_package = fetch_benefit_group(legal_name)
  attributes[:rating_area_id] = benefit_package.benefit_application.recorded_rating_area_id
  # get rid of this we no longer set benefit_package on hbx_enrollment object
  # attributes[:benefit_package] = benefit_package
  attributes[:sponsored_benefit_id] = benefit_package.sponsored_benefits.first.id
  attributes[:sponsored_benefit_package_id] = benefit_package.id
  build_enrollment(attributes, :with_health_product)
end
