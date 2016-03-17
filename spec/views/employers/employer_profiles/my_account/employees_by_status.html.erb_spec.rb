require "rails_helper"

RSpec.describe "employers/employer_profiles/my_account/_employees_by_status.html.erb" do
  let(:employer_profile) { FactoryGirl.create(:employer_profile) }
  let(:census_employee1) { FactoryGirl.create(:census_employee, employer_profile: employer_profile) }
  let(:census_employee2) { FactoryGirl.create(:census_employee, employer_profile: employer_profile) }
  let(:census_employee3) { FactoryGirl.create(:census_employee, employer_profile: employer_profile) }
  let(:census_employees) { [census_employee1, census_employee2, census_employee3] }


  let(:user) { FactoryGirl.create(:user) }
  let(:family) { FactoryGirl.create(:family, :with_primary_family_member) }

  let(:user) { FactoryGirl.create(:user) }

  before :each do
    benefit_group = FactoryGirl.create(:benefit_group)
    plan_year = benefit_group.plan_year
    employer_profile = plan_year.employer_profile
    benefit_group_assignment = FactoryGirl.build(:benefit_group_assignment, benefit_group: benefit_group)
    valid_person_params = { user: user, first_name: census_employee1.first_name, last_name: census_employee1.last_name, gender: census_employee1.gender}
    valid_employee_params = { ssn: census_employee1.ssn, gender: census_employee1.gender, dob: census_employee1.dob, hired_on: census_employee1.hired_on}
    valid_params = { employer_profile: employer_profile }.merge(valid_person_params).merge(valid_employee_params)
    params = valid_params
    person = FactoryGirl.create(:person, valid_person_params.except(:user).merge(dob: census_employee1.dob, ssn: census_employee1.ssn))
    family.person_id = person.id
    hbx_enrollment = FactoryGirl.create(:hbx_enrollment, household: family.active_household, benefit_group: benefit_group, benefit_group_assignment: benefit_group_assignment)



    allow(census_employee1).to receive(:active_benefit_group_assignment).and_return(double(aasm_state: "initialized", benefit_group:  BenefitGroup.new({title:"sample"}), hbx_enrollment: hbx_enrollment))
    allow(census_employee2).to receive(:active_benefit_group_assignment).and_return(double(aasm_state: "coverage_selected", benefit_group: BenefitGroup.new({title:"sample"}), hbx_enrollment: hbx_enrollment))
    allow(census_employee3).to receive(:active_benefit_group_assignment).and_return(double(aasm_state: "coverage_terminated", benefit_group: BenefitGroup.new({title:"sample"}), hbx_enrollment: hbx_enrollment))
    assign(:employer_profile, employer_profile)
    assign(:page_alphabets, ['a', 'b', 'c'])

    sign_in user
    stub_template "shared/alph_paginate" => ''
  end

  it "should displays enrollment state" do
    assign(:census_employees, census_employees)
    render "employers/employer_profiles/my_account/employees_by_status", :status => "all"
    expect(rendered).to match(/Enrollment Status/)
    expect(rendered).to match(/Coverage selected/)
    expect(rendered).to match(/Coverage terminated/)
  end

  it "should displays search result title" do
    assign(:search, true)
    assign(:census_employees, census_employees)
    render "employers/employer_profiles/my_account/employees_by_status", :status => "all"
    census_employees.each do |ce|
      expect(rendered).to match /.*#{ce.first_name}.*#{ce.last_name}.*/
    end
  end

  it "should displays no results found" do
    assign(:search, true)
    assign(:census_employees, [])
    render "employers/employer_profiles/my_account/employees_by_status", :status => "all"
    expect(rendered).to match /No results found/
  end
end
