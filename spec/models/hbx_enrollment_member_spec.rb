require 'rails_helper'

describe HbxEnrollmentMember, type: :model do
  context "an hbx_enrollment with members exists" do
    include_context "BradyWork"

    let(:household) {mikes_family.households.first}
    let(:coverage_household) {household.coverage_households.first}
    let(:enrollment) do
      household.create_hbx_enrollment_from(
        employer_profile: mikes_employer,
        coverage_household: coverage_household,
        benefit_group: mikes_benefit_group
      )
    end
    let(:family_member_ids) {mikes_family.family_members.collect(&:_id)}

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
