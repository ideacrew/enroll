require 'rails_helper'

describe HbxEnrollmentMember, dbclean: :after_all do
  context "an hbx_enrollment with members exists" do
    include_context "BradyWorkAfterAll"

    attr_reader :household, :coverage_household, :enrollment, :family_member_ids
    before :all do
      create_brady_census_families
      @household = mikes_family.households.first
      @coverage_household = household.coverage_households.first
      @enrollment = household.create_hbx_enrollment_from(
        employee_role: mikes_employee_role,
        coverage_household: coverage_household,
        benefit_group: mikes_benefit_group
      )
      @family_member_ids = mikes_family.family_members.collect(&:_id)
    end

    context "the first hbx enrollment member" do
      let!(:enrollment_member) {enrollment.hbx_enrollment_members.first}

      it "should have a family member" do
        expect(family_member_ids).to include(enrollment_member.family_member._id)
      end

      it "should know its relationship to the subscriber" do
        expect(enrollment_member.primary_relationship).to eq enrollment_member.family_member.primary_relationship
      end
    end

    context "validate hbx_enrollment_member" do
      let!(:subscriber) {enrollment.hbx_enrollment_members.first}
      let!(:enrollment_members) {enrollment.hbx_enrollment_members}

      it "should not raise error if subscriber(primary applicant) is selected during enrollment" do
        expect(@enrollment.valid?).to be_truthy
        expect(@enrollment.hbx_enrollment_members.first.errors[:is_subscriber].any?).to be_falsey
      end

      it "should raise if subscriber(primary applicant) is not selected during enrollment" do
        enrollment_members.reject!{ |a| a._id == subscriber._id }
        expect(@enrollment.valid?).to be_falsey
        expect(@enrollment.hbx_enrollment_members.first.errors[:is_subscriber].any?).to be_truthy
      end

    end
  end
end
