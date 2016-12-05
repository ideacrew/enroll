require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "remove_invalid_benefit_group_assignments_for_employer")

describe RemoveInvalidBenefitGroupAssignmentsForEmployer do

  let(:given_task_name) { "remove_invalid_benefit_group_assignments_for_employer" }
  subject { RemoveInvalidBenefitGroupAssignmentsForEmployer.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing plan year's state" do

    let!(:benefit_group_one)     { FactoryGirl.create(:benefit_group, plan_year: plan_year)}
    let!(:plan_year)         { FactoryGirl.create(:plan_year, aasm_state: "draft", employer_profile: employer_profile) }
    let(:employer_profile)  { FactoryGirl.create(:employer_profile) }
    let(:census_employee) { FactoryGirl.create(:census_employee, employer_profile_id: employer_profile.id)}

    before(:each) do
      allow(ENV).to receive(:[]).with("fein").and_return(employer_profile.parent.fein)
    end

    context "checking benefit group assignments", dbclean: :after_each do

      it "should remove the invalid benefit group assignments" do
        expect(census_employee.benefit_group_assignments.size).to eq 1
        census_employee.benefit_group_assignments.first.benefit_group.delete
        subject.migrate
        census_employee.reload
        expect(census_employee.benefit_group_assignments.size).to eq 0
      end

      it "should not remove the valid benefit group assignment" do
        subject.migrate
        census_employee.reload
        expect(census_employee.benefit_group_assignments.size).to eq 1
      end
    end
  end
end
