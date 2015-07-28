require 'rails_helper'

describe CoverageHousehold, type: :model do
  context "family_members" do
    let(:coverage_household) {CoverageHousehold.new}
    let(:family) {Family.new}
    let(:family_members) {[family_member1, family_member2]}
    let(:family_member1) {double(is_active?: true)}
    let(:family_member2) {double(is_active?: false)}

    it "should return blank array" do
      allow(coverage_household).to receive(:family).and_return(nil)
      expect(coverage_household.family_members).to eq []
    end

    it "should return active_family_members" do
      allow(coverage_household).to receive(:family).and_return(family)
      allow(family).to receive(:family_members).and_return(family_members)
      expect(coverage_household.family_members).to eq [family_member1]
    end
  end
end
