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
        employer_profile: mikes_employer,
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
  end
end
