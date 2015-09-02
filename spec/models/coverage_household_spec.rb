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

describe CoverageHousehold, "when informed that eligiblity has changed for an individual" do
  let(:mock_person) { double }
  let(:matching_coverage_household) { instance_double("CoverageHousehold") }
  let(:mock_household) { instance_double("Household", :coverage_households => [matching_coverage_household]) }
  let(:mock_family) { instance_double("Family", :households => [mock_household]) }

  it "should locate and notify each coverage household containing that individual" do
    allow(Family).to receive(:find_all_by_person).with(mock_person).and_return([mock_family])
    expect(matching_coverage_household).to receive(:evaluate_individual_market_eligiblity)
    CoverageHousehold.update_individual_eligibilities_for(mock_person)
  end
end
