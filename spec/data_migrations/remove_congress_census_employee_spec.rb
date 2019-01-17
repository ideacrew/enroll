require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "remove_congress_census_employee")
describe RemoveCongressCensusEmployee, dbclean: :after_each do
  describe "given a task name" do
    let(:given_task_name) { "remove_congress_census_employee" }
    subject {RemoveCongressCensusEmployee.new(given_task_name, double(:current_scope => nil)) }
      it "has the given task name" do
        expect(subject.name).to eql given_task_name
      end
    end
    
  describe "remove a census employee from congressional roster" do
    subject {RemoveCongressCensusEmployee.new("remove_congress_census_employee", double(:current_scope => nil)) }
    let!(:employer_profile){ create :employer_profile, aasm_state: "active"}
    let!(:person){ create :person}
    let(:employee_role) {FactoryGirl.create(:employee_role, person: person, employer_profile: employer_profile)}
    let(:census_employee) { FactoryGirl.create(:census_employee, employee_role_id: employee_role.id, employer_profile_id: employer_profile.id) }
    let!(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: TimeKeeper.date_of_record.beginning_of_year, :aasm_state => 'published' ) }
    let!(:active_benefit_group) { FactoryGirl.create(:benefit_group, is_congress: false, plan_year: plan_year, title: "Benefits #{plan_year.start_on.year}") }
    let(:benefit_group_assignment)  { FactoryGirl.create(:benefit_group_assignment, benefit_group: active_benefit_group, census_employee: census_employee) }
    
      before :each do
        allow(ENV).to receive(:[]).with('census_employee_id').and_return census_employee.id
      end
      
      it "should not remove census employee if they are NOT is_congress" do
        expect(employer_profile.census_employees.count).to eq 1
        subject.migrate
        expect(employer_profile.census_employees.count).to eq 1
      end
      
      it "should do remove census employee if benefit_group is_congress is set to true" do
        active_benefit_group.update(is_congress:true)
        expect(employer_profile.census_employees.count).to eq 1
        subject.migrate
        expect(employer_profile.census_employees.count).to eq 0
      end
    end
   
end
