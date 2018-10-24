require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "deactivate_benefit_group_assignment")

describe DeactivateBenefitGroupAssignment do
  let(:given_task_name) { "deactivate_benefit_group_assignment" }
  subject { DeactivateBenefitGroupAssignment.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "deactivate benefit group assignment" do
    let!(:census_employee) { FactoryGirl.create(:census_employee,ssn:"123456789")}
    let!(:benefit_group_assignment1)  { FactoryGirl.create(:benefit_group_assignment, is_active: true, census_employee: census_employee)}
    let!(:benefit_group_assignment2)  { FactoryGirl.create(:benefit_group_assignment, is_active: true, census_employee: census_employee)}
    before(:each) do
      allow(ENV).to receive(:[]).with("ce_ssn").and_return(census_employee.ssn)
      allow(ENV).to receive(:[]).with("bga_id").and_return(benefit_group_assignment1.id)
    end
    context "deactivate_benefit_group_assignment", dbclean: :after_each do
      it "should deactivate_related_benefit_group_assignment" do
        expect(benefit_group_assignment1.is_active).to eq true
        plan_year=benefit_group_assignment1.plan_year
        subject.migrate
        benefit_group_assignment1.reload
        benefit_group_assignment2.reload
        expect(benefit_group_assignment1.is_active).to eq false
        expect(benefit_group_assignment1.end_on).to eq plan_year.end_on
        expect(benefit_group_assignment2.is_active).to eq true
      end
    end
  end
end

