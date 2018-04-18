require "rails_helper"
require 'byebug'

require File.join(Rails.root,"app","data_migrations","update_waiver_reason")

describe UpdateWaiverReason, dbclean: :after_each do 
  let(:given_task_name) {"update_waiver_reason"}
  subject { UpdateWaiverReason.new(given_task_name, double(:current_scope=>nil))}

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "update waiver reason" do
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member)}
    let(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, household: family.active_household, waiver_reason: "this is the reason")}
    let(:hbx_enrollment2) { FactoryGirl.create(:hbx_enrollment, household: family.active_household)}
    let(:term_enrollment) { FactoryGirl.create(:hbx_enrollment, :terminated, household: family.active_household)}
    let(:term_enrollment2) { FactoryGirl.create(:hbx_enrollment, :terminated, household: family.active_household)}
    let(:term_enrollment3) { FactoryGirl.create(:hbx_enrollment, :terminated, household: family.active_household, kind: "individual")}
    let(:new_plan) { FactoryGirl.create(:plan) }
    let(:new_benefit_group) { FactoryGirl.create(:benefit_group) }

    before :each do 
      allow(ENV).to receive(:[]).with("id").and_return("#{hbx_enrollment.hbx_id}")
      allow(ENV).to receive(:[]).with("waiver_reason").and_return("waiver_reason")
    end


    it "should change effective on date" do
      expect(hbx_enrollment.waiver_reason).to eq "this is the reason"
      subject.migrate
      hbx_enrollment.reload
      expect(hbx_enrollment.waiver_reason).to eq "waiver_reason"

    end
  end
end
