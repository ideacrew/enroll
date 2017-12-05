require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "deactivate_terminated_benefit_package")

describe DeactivateTerminatedBenefitPackage, dbclean: :after_each do

  let(:given_task_name) { "deactivate_terminated_benefit_package" }
  subject { DeactivateTerminatedBenefitPackage.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "deactivate terminated benefit package" do

    let!(:benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year)}
    let(:plan_year) { FactoryGirl.create(:plan_year) }
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member) }
    let(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment,household: family.active_household)}
    let(:benefit_group_assignment) {FactoryGirl.build(:benefit_group_assignment, benefit_group: benefit_group, hbx_enrollment: hbx_enrollment, start_on: TimeKeeper.date_of_record - 5.years)}
    let(:census_employee) { FactoryGirl.create(:census_employee, employer_profile_id: plan_year.employer_profile.id)}

    before(:each) do
      census_employee.benefit_group_assignments.first.update_attribute("aasm_state", "coverage_terminated")
      census_employee.reload
    end

    context "updating benefit group assignments", dbclean: :after_each do

      it "should update the invalid benefit group assignments" do
        subject.migrate
        census_employee.reload
        census_employee.benefit_group_assignments.each do |bga|
          expect(bga.is_active?).to be_falsey
        end
      end

    end
  end
end