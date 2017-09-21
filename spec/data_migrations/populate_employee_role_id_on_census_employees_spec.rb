require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "populate_employee_role_id_on_census_employees")

describe PopulateEmployeeRoleIdOnCensusEmployees do

  let(:given_task_name) { "populate_employee_role_id_on_census_employees" }
  subject { PopulateEmployeeRoleIdOnCensusEmployees.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "populating employee role id on census employee" do
    
    let(:employer_profile) { FactoryGirl.create(:employer_profile) }
    let(:organization) { FactoryGirl.create(:organization,employer_profile:employer_profile)}
    let(:census_employee){ FactoryGirl.create(:census_employee,employer_profile_id:employer_profile.id)}
    let!(:person) { FactoryGirl.create(:person_with_employee_role, ssn:census_employee.ssn,census_employee_id:census_employee.id,employer_profile_id:employer_profile.id,hired_on:census_employee.hired_on) }

    before(:each)  do
      census_employee.aasm_state='employment_terminated'
      census_employee.save
      allow(ENV).to receive(:[]).with("fein").and_return(organization.fein)
    end

    context "populate_employee_role_id_on_census_employees", dbclean: :after_each do
      it "should populate_employee_role_id_on_census_employees" do
        subject.migrate
        expect(census_employee.employee_role_id).to eq nil
        census_employee.reload
        expect(census_employee.employee_role_id).to eq (person.employee_roles.first.id)
      end
    end

  end
end