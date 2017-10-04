require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "terminate_employee_from_employer")

describe TerminateEmployeeRole, dbclean: :after_each do
  let(:given_task_name) { "terminate_employee_from_employer" }
  subject { TerminateEmployeeRole.new(given_task_name, double(:current_scope => nil)) }
  
  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  
  describe "terminates census employee for an employer" do
    let(:employer_profile) { FactoryGirl.create(:employer_profile, plan_years: [plan_year])}
    let(:person) { FactoryGirl.create(:person, :with_employee_role) }
    let(:census_employee){FactoryGirl.create(:census_employee, employer_profile: employer_profile, benefit_group_assignments: [benefit_group_assignment])}
    let(:benefit_group) { FactoryGirl.build(:benefit_group) }
    let(:plan_year)  { FactoryGirl.build(:plan_year, benefit_groups: [benefit_group], start_on: Date.new(Date.today.year,Date.today.month,1)) }
    let(:benefit_group_assignment) { FactoryGirl.build(:benefit_group_assignment, benefit_group: benefit_group) }
    
    before(:each) do
      allow(ENV).to receive(:[]).with('hbx_id').and_return(person.hbx_id)
      allow(ENV).to receive(:[]).with('emp_id').and_return(person.employee_roles.first.id)
      person.employee_roles.first.update(census_employee_id:census_employee.id)
    end

    it "should terminate specific employee" do
      expect(person.employee_roles.first.census_employee.aasm_state).to eq "eligible"
      subject.migrate
      person.employee_roles.first.census_employee.reload
      expect(person.employee_roles.first.census_employee.aasm_state).to eq "employment_terminated"
    end
  end
  
end