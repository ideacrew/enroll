require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "make_benefit_group_assignment_active")

describe MakeBenefitGroupAssignmentActive, dbclean: :after_each do

  let(:given_task_name) { "make_benefit_group_assignment_active" }
  subject { MakeBenefitGroupAssignmentActive.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "creates an inactive benefit group assignment" do


    let!(:benefit_group) { FactoryBot.create(:benefit_group, plan_year: plan_year)}
    let(:plan_year) { FactoryBot.create(:plan_year) }
    let(:family) { FactoryBot.create(:family, :with_primary_family_member) }
    let(:benefit_group_assignment) {FactoryBot.build(:benefit_group_assignment, benefit_group: benefit_group, start_on: TimeKeeper.date_of_record)}
    let(:census_employee) { FactoryBot.create(:census_employee, :old_case, employer_profile_id: plan_year.employer_profile.id, benefit_group_assignments:[benefit_group_assignment])}

    before(:each) do
      allow(ENV).to receive(:[]).with("ce_id").and_return(census_employee.id)
      allow(benefit_group_assignment).to receive(:plan_year).and_return(plan_year)
      benefit_group_assignments = [benefit_group_assignment]
      allow(census_employee).to receive(:benefit_group_assignments).and_return benefit_group_assignments
      allow(benefit_group_assignment).to receive(:benefit_group).and_return(benefit_group)
      census_employee.benefit_group_assignments.last.update(is_active:false)
    end


    context "updating benefit group assignment to active", dbclean: :after_each do

      it "should make the benefit group assignment active" do
        expect(census_employee.benefit_group_assignments.last.is_active).to eq(false)
        subject.migrate
        census_employee.reload
        expect(CensusEmployee.find(census_employee.id).benefit_group_assignments.last.is_active).to eq(true)
      end

    end
  end
end
