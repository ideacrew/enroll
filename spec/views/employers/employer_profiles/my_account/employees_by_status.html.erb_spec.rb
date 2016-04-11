require "rails_helper"
  

  RSpec.describe "employers/employer_profiles/my_account/_employees_by_status.html.erb" do
    let(:employer_profile) { FactoryGirl.create(:employer_profile) }
    let(:census_employee1) { FactoryGirl.create(:census_employee, employer_profile: employer_profile) }
    let(:census_employee2) { FactoryGirl.create(:census_employee, employer_profile: employer_profile) }
    let(:census_employee3) { FactoryGirl.create(:census_employee, employer_profile: employer_profile) }
    let(:census_employees) { [census_employee1, census_employee2, census_employee3] }
  
    let(:person) { FactoryGirl.create(:person) }
    let(:employee_role) { FactoryGirl.create(:employee_role, person: person) }
    let(:primary_family) { FactoryGirl.create(:family, :with_primary_family_member) }
    let(:hbx_enrollment) {FactoryGirl.create(:hbx_enrollment, household: primary_family.active_household)}
    let(:enrollment_with_coverage_selected)   { FactoryGirl.create( :hbx_enrollment,
                                          household: primary_family.latest_household,
                                          employee_role_id: employee_role.id
                                       )}
    let(:enrollment_with_coverage_terminated)   { FactoryGirl.create( :hbx_enrollment,
                                      household: primary_family.latest_household,
                                      employee_role_id: employee_role.id,
                                      aasm_state: "coverage_terminated"
                                   )}

    let(:user) { FactoryGirl.create(:user) }
  

    before :each do
      allow(census_employee1).to receive(:active_benefit_group_assignment).and_return(double(aasm_state: "initialized", benefit_group:  BenefitGroup.new({title:"sample"})))
      allow(census_employee2).to receive(:active_benefit_group_assignment).and_return(double(aasm_state: "coverage_selected", benefit_group: BenefitGroup.new({title:"sample"})))
      allow(census_employee3).to receive(:active_benefit_group_assignment).and_return(double(aasm_state: "coverage_terminated", benefit_group: BenefitGroup.new({title:"sample"})))
      assign(:employer_profile, employer_profile)
      assign(:page_alphabets, ['a', 'b', 'c'])
      
      allow(person).to receive(:primary_family).and_return(primary_family)
      allow(census_employee1).to receive(:employee_role).and_return(employee_role)
      allow(census_employee2).to receive(:employee_role).and_return(employee_role)
      allow(census_employee3).to receive(:employee_role).and_return(employee_role)
      allow(person).to receive(:primary_family).and_return(primary_family)

      sign_in user
      stub_template "shared/alph_paginate" => ''
    end
  

    it "should displays enrollment state when coverage selected" do
      allow(primary_family).to receive(:enrolled_including_waived_hbx_enrollments).and_return([enrollment_with_coverage_selected])
      assign(:census_employees, census_employees)
      render "employers/employer_profiles/my_account/employees_by_status", :status => "all"
      expect(rendered).to match(/Enrollment Status/)
      expect(rendered).to match(/Coverage Selected/)
    end
  
    it "should displays enrollment state when inactive" do
      allow(primary_family).to receive(:enrolled_including_waived_hbx_enrollments).and_return([enrollment_with_coverage_terminated])
      
      assign(:census_employees, census_employees)
      render "employers/employer_profiles/my_account/employees_by_status", :status => "all"
      expect(rendered).to match(/Enrollment Status/)
      expect(rendered).to match(/Coverage Terminated/)
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
