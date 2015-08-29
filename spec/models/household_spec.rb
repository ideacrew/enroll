require 'rails_helper'

describe Household, "given a coverage household with a dependent" do
  let(:family_member) { FamilyMember.new }
  let(:coverage_household_member) { CoverageHouseholdMember.new(:family_member_id => family_member.id) }
  let(:coverage_household) { CoverageHousehold.new(:coverage_household_members => [coverage_household_member]) }

  subject { Household.new(:coverage_households => [coverage_household]) }

  it "should remove the dependent from the coverage households when removing them from the household" do
    expect(coverage_household).to receive(:remove_family_member).with(family_member)
    subject.remove_family_member(family_member)
  end

  it "should not have any enrolled hbx enrollments" do
    expect(subject.enrolled_hbx_enrollments).to eq []
  end

  # context "with an enrolled hbx enrollment" do
  #   let(:mock_hbx_enrollment) { instance_double(HbxEnrollment) }
  #   let(:hbx_enrollments) { [mock_hbx_enrollment] }
  #   before do
  #     allow(HbxEnrollment).to receive(:covered).with(hbx_enrollments).and_return(hbx_enrollments)
  #     allow(subject).to receive(:hbx_enrollments).and_return(hbx_enrollments)
  #   end

  #   it "should return the enrolled hbx enrollment in an array" do
  #     expect(subject.enrolled_hbx_enrollments).to eq hbx_enrollments
  #   end
  # end
end
