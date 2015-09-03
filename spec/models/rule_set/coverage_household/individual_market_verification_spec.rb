require "rails_helper"

describe RuleSet::CoverageHousehold::IndividualMarketVerification do
  subject { RuleSet::CoverageHousehold::IndividualMarketVerification.new(coverage_household) }
  let(:coverage_household) { instance_double(CoverageHousehold, :active_individual_enrollments => active_individual_policies) }

  describe "in a coverage household with no active individual policies" do
    let(:active_individual_policies) { [] } 
    it "should not be applicable" do
      expect(subject.applicable?).to eq false
    end
  end

  describe "in a coverage household with active individual policies" do
    let(:active_individual_policies) { [double] } 
    it "should be applicable" do
      expect(subject.applicable?).to eq true
    end
  end

end
