require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "revert_ce_termination")

describe RevertCeTermination, dbclean: :after_each do

  let(:given_task_name) { "revert_ce_termination" }
  subject { RevertCeTermination.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "revert ce_termination_from_termintion_pending_status", dbclean: :after_each do
    let(:census_employee) { FactoryGirl.build(:census_employee, :termination_details) }

    before do
      allow(ENV).to receive(:[]).with("census_employee_id").and_return(census_employee.id)
      census_employee.class.skip_callback(:save, :after, :assign_default_benefit_package)
      census_employee.save! # We can only change the census record SSN & DOB when CE is in "eligible" status
      census_employee.aasm_state = "employee_termination_pending"
      census_employee.save!
      subject.migrate
      census_employee.reload
    end

    after do
      census_employee.class.set_callback(:save, :after, :assign_default_benefit_package)
    end

    it "should show the state of census employee as linked" do
      expect(census_employee.aasm_state).to eq "employee_role_linked"
    end

    it "should unset employment_terminated_on on census_employee" do
      expect(census_employee.employment_terminated_on).to eq nil
    end

    it "should unset coverage_terminated_on on census_employee" do
      expect(census_employee.employment_terminated_on).to eq nil
    end

  end
end
