require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "invalidate_hbx_enrollment_with_broken_current_premium")

describe InvalidateHbxEnrollmentWithBrokenCurrentPremium do

  let(:given_task_name) { "invalidate_hbx_enrollment_with_broken_current_premium" }
  subject { InvalidateHbxEnrollmentWithBrokenCurrentPremium.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "total premium" do
    let(:family) { FactoryBot.create(:family, :with_primary_family_member) }
    let(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, family: family, household: family.active_household) }

    context "void enrollment" do
      it "should invalidate enrollment" do
        ClimateControl.modify :enrollment_id => hbx_enrollment._id, :plan_id => plan._id do
          expect(hbx_enrollment.plan_id).to eq nil
          expect(hbx_enrollment.carrier_profile_id).to eq nil
          subject.migrate
          hbx_enrollment.reload
          expect(hbx_enrollment.plan_id).to eq plan.id
          expect(hbx_enrollment.carrier_profile_id).to eq plan.carrier_profile_id
        end
      end
    end

    context "active enrollment" do
      it "should throw error message and not invalidate active enrollment" do
      end
    end
  end
end
