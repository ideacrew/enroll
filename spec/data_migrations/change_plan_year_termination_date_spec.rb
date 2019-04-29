require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_plan_year_termination_date")

describe ChangePlanYearTerminationDate do

  let(:given_task_name) { "change_plan_year_termination_date" }
  subject { ChangePlanYearTerminationDate.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  describe "change end date of a terminated plan year", dbclean: :after_each do
    let(:benefit_group) { FactoryGirl.create(:benefit_group)}
    let(:plan_year) { FactoryGirl.create(:plan_year, benefit_groups: [benefit_group], aasm_state: "terminated")}
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member)}
    let!(:enrollment) { FactoryGirl.create(:hbx_enrollment, household: family.active_household, aasm_state: "coverage_terminated", benefit_group_id: plan_year.benefit_groups.first.id)}
    before(:each) do
      allow(ENV).to receive(:[]).with('plan_year_start_on').and_return(plan_year.start_on.to_s)
      allow(ENV).to receive(:[]).with('fein').and_return(plan_year.employer_profile.parent.fein)
      allow(ENV).to receive(:[]).with('new_terminated_on').and_return((plan_year.start_on+30.day).to_s) 
    end
    it "should update the end date of a terminated plan year" do
      expect(plan_year.aasm_state).to eq "terminated"
      subject.migrate
      plan_year.reload
      expect(plan_year.aasm_state).to eq "terminated"
      expect(plan_year.end_on.to_s).to eq (plan_year.start_on+30.day).to_s
    end
  end
  describe "change end date of a terminated plan year", dbclean: :after_each do
    let(:benefit_group) { FactoryGirl.create(:benefit_group)}
    let(:plan_year) { FactoryGirl.create(:plan_year, benefit_groups: [benefit_group], aasm_state: "enrolled")}
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member)}
    let!(:enrollment) { FactoryGirl.create(:hbx_enrollment, household: family.active_household, aasm_state: "coverage_enrolled", benefit_group_id: plan_year.benefit_groups.first.id)}
    before(:each) do
      allow(ENV).to receive(:[]).with('plan_year_start_on').and_return(plan_year.start_on.to_s)
      allow(ENV).to receive(:[]).with('fein').and_return(plan_year.employer_profile.parent.fein)
      allow(ENV).to receive(:[]).with('new_terminated_on').and_return((plan_year.start_on+30.day).to_s) 
    end
    it "should update the end date of a terminated plan year" do
      expect(plan_year.aasm_state).to eq "enrolled"
      subject.migrate
      plan_year.reload
      expect(plan_year.aasm_state).not_to eq "terminated"
    end
  end
end
