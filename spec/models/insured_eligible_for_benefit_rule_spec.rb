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

  context "is_cost_sharing_satisfied?" do
    include_context "BradyBunchAfterAll"
    before :all do
      create_tax_household_for_mikes_family
      @consumer_role = mike.consumer_role
    end
    let(:benefit_coverage_period) {FactoryGirl.build(:benefit_coverage_period, start_on: TimeKeeper.date_of_record)}
    let(:benefit_package) {FactoryGirl.build(:benefit_package, benefit_coverage_period: benefit_coverage_period)}

    it "should return true when csr_kind is blank" do
      rule = InsuredEligibleForBenefitRule.new(ConsumerRole.new, benefit_package)
      expect(rule.is_cost_sharing_satisfied?).to eq true
    end

    it "should return true when cost_sharing is blank" do
      rule = InsuredEligibleForBenefitRule.new(@consumer_role, FactoryGirl.build(:benefit_package))
      expect(rule.is_cost_sharing_satisfied?).to eq true
    end

    it "should return true when cost_sharing is equal to csr_kind" do
      benefit_package.benefit_eligibility_element_group.cost_sharing = 'csr_87'
      rule = InsuredEligibleForBenefitRule.new(@consumer_role, benefit_package)
      expect(rule.is_cost_sharing_satisfied?).to eq true
    end

    it "should return false when cost_sharing is not equal to csr_kind" do
      benefit_package.benefit_eligibility_element_group.cost_sharing = 'csr_100'
      rule = InsuredEligibleForBenefitRule.new(@consumer_role, benefit_package)
      expect(rule.is_cost_sharing_satisfied?).to eq false
    end
  end

  context "is_residency_status_satisfied?" do
    let(:consumer_role) {double}
    let(:benefit_package) {double}

    it "return true if residency status include 'any'" do
      allow(benefit_package).to receive(:residency_status).and_return ["any", "other"]
      rule = InsuredEligibleForBenefitRule.new(consumer_role, benefit_package)
      expect(rule.is_residency_status_satisfied?).to eq true
    end

    it "return false when consumer_role is nil" do
      allow(benefit_package).to receive(:residency_status).and_return ["other"]
      rule = InsuredEligibleForBenefitRule.new(nil, benefit_package)
      expect(rule.is_residency_status_satisfied?).to eq false
    end

    describe "include state_resident" do 
      let(:family_member) {double}
      let(:family) {double(family_members: double(active: [family_member]))}
      let(:person) {double(families: [family])}
      let(:consumer_role) {double(person: person)}
      let(:benefit_package) {double}

      before :each do
        allow(benefit_package).to receive(:residency_status).and_return ["state_resident", "other"] 
      end

      it "return true if is dc resident" do
        allow(person).to receive(:is_dc_resident?).and_return true
        rule = InsuredEligibleForBenefitRule.new(consumer_role, benefit_package)
        expect(rule.is_residency_status_satisfied?).to eq true
      end

      context "is not dc resident" do
        before :each do
          allow(person).to receive(:is_dc_resident?).and_return false
        end

        it "return true if any one's age >= 19 and is dc resident" do
          allow(family_member).to receive(:dob).and_return (TimeKeeper.date_of_record - 20.years)
          allow(family_member).to receive(:is_dc_resident?).and_return true
          rule = InsuredEligibleForBenefitRule.new(consumer_role, benefit_package)
          expect(rule.is_residency_status_satisfied?).to eq true
        end

        it "return false if all < 19" do
          allow(family_member).to receive(:dob).and_return (TimeKeeper.date_of_record - 10.years)
          rule = InsuredEligibleForBenefitRule.new(consumer_role, benefit_package)
          expect(rule.is_residency_status_satisfied?).to eq false
        end

        it "return false if all are not dc resident" do
          allow(family_member).to receive(:dob).and_return (TimeKeeper.date_of_record - 20.years)
          allow(family_member).to receive(:is_dc_resident?).and_return false
          rule = InsuredEligibleForBenefitRule.new(consumer_role, benefit_package)
          expect(rule.is_residency_status_satisfied?).to eq false
        end

        it "return false if all < 19 and all are not dc resident" do
          allow(family_member).to receive(:dob).and_return (TimeKeeper.date_of_record - 10.years)
          allow(family_member).to receive(:is_dc_resident?).and_return false
          rule = InsuredEligibleForBenefitRule.new(consumer_role, benefit_package)
          expect(rule.is_residency_status_satisfied?).to eq false

        end
      end

    end
  end
end
