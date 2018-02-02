require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_enrollment_details")

describe ChangeEnrollmentDetails do

  let(:given_task_name) { "change_enrollment_details" }
  subject { ChangeEnrollmentDetails.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing enrollment attributes" do

    let(:family) { FactoryGirl.create(:family, :with_primary_family_member)}
    let(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, aasm_state:'coverage_expired', household: family.active_household)}
    let(:hbx_enrollment2) { FactoryGirl.create(:hbx_enrollment, household: family.active_household)}
    let(:term_enrollment) { FactoryGirl.create(:hbx_enrollment, :terminated, household: family.active_household)}
    let(:term_enrollment2) { FactoryGirl.create(:hbx_enrollment, :terminated, household: family.active_household)}
    let(:term_enrollment3) { FactoryGirl.create(:hbx_enrollment, :terminated, household: family.active_household, kind: "individual")}
    let(:new_plan) { FactoryGirl.create(:plan) }
    let(:new_benefit_group) { FactoryGirl.create(:benefit_group) }


    it "should move enrollment to enrolled status" do
      allow(ENV).to receive(:[]).with("hbx_id").and_return("#{hbx_enrollment.hbx_id}")
      allow(ENV).to receive(:[]).with("action").and_return "revert_enrollment"
      subject.migrate
      hbx_enrollment.reload
      expect(hbx_enrollment.aasm_state).to eq "coverage_enrolled"
    end

    it "should expire the enrollment" do
      allow(ENV).to receive(:[]).with("hbx_id").and_return("#{hbx_enrollment2.hbx_id}")
      allow(ENV).to receive(:[]).with("action").and_return "expire_enrollment"
      subject.migrate
      hbx_enrollment2.reload
      expect(hbx_enrollment2.aasm_state).to eq "coverage_expired"
    end
  end
end
