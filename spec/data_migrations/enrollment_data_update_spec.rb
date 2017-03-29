require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "enrollment_data_update")

describe EnrollmentDataUpdate do

  let(:given_task_name) { "enrollment data update" }
  subject { EnrollmentDataUpdate.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "shop enrollment case " do

    let(:family) { FactoryGirl.create(:family, :with_primary_family_member)}
    let!(:hbx_enrollment1) { FactoryGirl.create(:hbx_enrollment, household: family.active_household, aasm_state: "coverage_canceled")}
    let!(:hbx_enrollment2) { FactoryGirl.create(:hbx_enrollment, household: family.active_household)}
    let!(:hbx_enrollment_member1) {FactoryGirl.create(:hbx_enrollment_member,hbx_enrollment: hbx_enrollment1,applicant_id: family.primary_family_member.id,eligibility_date: Date.new(2016,1,1))}
    let!(:hbx_enrollment_member2) {FactoryGirl.create(:hbx_enrollment_member,hbx_enrollment: hbx_enrollment2,applicant_id: family.primary_family_member.id,eligibility_date: Date.new(2016,1,1))}
    before(:each) do

    end

    it "should change enrollment 1's state" do
      expect(hbx_enrollment1.aasm_state).to eq "coverage_canceled"
      subject.migrate
      family.reload
      expect(family.active_household.hbx_enrollments.where(id:hbx_enrollment1.id).first.aasm_state).to eq "coverage_terminated "
    end
  end
  # describe "ivl enrollment case " do
  #
  #   let(:family) { FactoryGirl.create(:family, :with_primary_family_member)}
  #   let(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, household: family.active_household)}
  #
  #   before(:each) do
  #     allow(ENV).to receive(:[]).with("hbx_id").and_return(hbx_enrollment.hbx_id)
  #     allow(ENV).to receive(:[]).with("new_effective_on").and_return(hbx_enrollment.effective_on + 1.month)
  #   end
  #
  #   it "should change effective on date" do
  #     effective_on = hbx_enrollment.effective_on
  #     subject.migrate
  #     hbx_enrollment.reload
  #     expect(hbx_enrollment.effective_on).to eq effective_on + 1.month
  #   end
  # end
end
