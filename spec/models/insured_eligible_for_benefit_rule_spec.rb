require 'rails_helper'

RSpec.describe InsuredEligibleForBenefitRule, :type => :model do
  context "#is_benefit_categories_satisfied?" do
    let(:consumer_role) {double}
    let(:benefit_package) {double}

    it "should return true" do
      allow(benefit_package).to receive(:benefit_categories).and_return(['health', 'dental'])
      rule = InsuredEligibleForBenefitRule.new(consumer_role, benefit_package, 'dental')
      expect(rule.is_benefit_categories_satisfied?).to eq true
    end

    it "should return false" do
      allow(benefit_package).to receive(:benefit_categories).and_return(['health'])
      rule = InsuredEligibleForBenefitRule.new(consumer_role, benefit_package, 'dental')
      expect(rule.is_benefit_categories_satisfied?).to eq false
    end

    it "coverage_kind" do
      allow(benefit_package).to receive(:benefit_categories).and_return(['health'])
      rule = InsuredEligibleForBenefitRule.new(consumer_role, benefit_package)
      expect(rule.is_benefit_categories_satisfied?).to eq true
    end
  end

  context "#is_age_range_satisfied?" do
    let(:consumer_role) {double(dob: (TimeKeeper.date_of_record - 20.years))}
    let(:benefit_package) {double}

    it "should return true when 0..0" do
      allow(benefit_package).to receive(:age_range).and_return (0..0)
      rule = InsuredEligibleForBenefitRule.new(consumer_role, benefit_package)
      expect(rule.is_age_range_satisfied?).to eq true
    end

    it "should return true when in the age range" do
      allow(benefit_package).to receive(:age_range).and_return (0..30)
      rule = InsuredEligibleForBenefitRule.new(consumer_role, benefit_package)
      expect(rule.is_age_range_satisfied?).to eq true
    end

    it "should return false when out of the age range" do
      allow(benefit_package).to receive(:age_range).and_return (0..10)
      rule = InsuredEligibleForBenefitRule.new(consumer_role, benefit_package)
      expect(rule.is_age_range_satisfied?).to eq false
    end
  end
end
