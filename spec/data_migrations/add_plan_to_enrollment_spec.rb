require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "add_plan_to_enrollment")

describe AddPlantoEnrollment do

  let(:given_task_name) { "add_plan_to_enrollment" }
  subject { AddPlantoEnrollment.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "enrollment with no plan" do
    
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member)}
    let(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, household: family.active_household)}
    let(:plan) { FactoryGirl.create(:plan, :with_premium_tables, active_year: TimeKeeper.date_of_record.year)}


    before(:each) do
      allow(ENV).to receive(:[]).with("enrollment_id").and_return(hbx_enrollment._id)
      allow(ENV).to receive(:[]).with("plan_id").and_return(plan._id)
      hbx_enrollment.update(plan_id:'', carrier_profile_id:'')
    end

    it "should add a plan to enrollment" do
      expect(hbx_enrollment.plan_id).to eq nil
      expect(hbx_enrollment.carrier_profile_id).to eq nil
      subject.migrate
      hbx_enrollment.reload
      expect(hbx_enrollment.plan_id).to eq plan.id
      expect(hbx_enrollment.carrier_profile_id).to eq plan.carrier_profile_id
    end
  end
end