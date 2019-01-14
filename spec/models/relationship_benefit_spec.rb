require 'rails_helper'

describe RelationshipBenefit do

  let(:relationship_benefit_params){
    {
      relationship: "employee",
      premium_pct: 60,
      employer_max_amt: 1000.00,
      offered: true
    }
  }

  let(:params){relationship_benefit_params}

  context "created with valid params" do
    let(:relationship_benefit) {RelationshipBenefit.new(**params)}

    it "should have the correct premium percent" do
      expect(relationship_benefit.premium_pct).to eq params[:premium_pct]
    end
    
    context "then premium percent is set to nil" do
      before do
        relationship_benefit.premium_pct = nil
      end

      it "should have a premium percent of 0" do
        expect(relationship_benefit.premium_pct).to eq 0.0
      end
    end
  end

  context "created without a premium percent" do
    let(:relationship_benefit) {RelationshipBenefit.new(**(params.except(:premium_pct)))}

    it "should default premium percent to 0" do
      expect(relationship_benefit.premium_pct).to eq 0.0
    end
  end

  context "created with a float premium_pct" do
    let(:relationship_benefit1_params){
      {
        relationship: "employee",
        premium_pct: 60.12,
        employer_max_amt: 1000.00,
        offered: true
      }
    }
    let(:relationship_benefit2_params){
      {
        relationship: "employee",
        premium_pct: 60.56,
        employer_max_amt: 1000.00,
        offered: true
      }
    }

    it "should premium percent to 60" do
      relationship_benefit = RelationshipBenefit.new(**(relationship_benefit1_params))
      expect(relationship_benefit.premium_pct).to eq 60.0
    end

    it "should premium percent to 61" do
      relationship_benefit = RelationshipBenefit.new(**(relationship_benefit2_params))
      expect(relationship_benefit.premium_pct).to eq 61.0
    end
  end

  context "created with a string premium_pct" do
    let(:relationship_benefit_params){
      {
        relationship: "employee",
        premium_pct: "60.12",
        employer_max_amt: 1000.00,
        offered: true
      }
    }

    it "should premium percent to 60" do
      relationship_benefit = RelationshipBenefit.new(**(relationship_benefit_params))
      expect(relationship_benefit.premium_pct).to eq 60.0
    end
  end

  context " should return offered?" do
    it "should return true if its true" do
      expect(RelationshipBenefit.new(**params).offered?).to eq true
    end

    it "should return false if its false" do
      params.deep_merge!({offered: false})
      expect(RelationshipBenefit.new(**params).offered?).to eq false
    end
  end

  context "validation" do
    let(:benefit_group) {FactoryBot.build(:benefit_group)}
    let(:relationship_benefit) { FactoryBot.create(:relationship_benefit, benefit_group: benefit_group) }

    it "should success" do
      relationship_benefit.premium_pct = 70
      expect(relationship_benefit.valid?).to be_truthy
      expect(relationship_benefit.errors[:premium_pct].any?).to be_falsey
    end
    
    context "should fail" do
      it "when greater than 100" do
        relationship_benefit.premium_pct = 120
        expect(relationship_benefit.valid?).to be_falsey
        expect(relationship_benefit.errors[:premium_pct].any?).to be_truthy
      end

      it "when less than 0" do
        relationship_benefit.premium_pct = -20
        expect(relationship_benefit.valid?).to be_falsey
        expect(relationship_benefit.errors[:premium_pct].any?).to be_truthy
      end
    end
  end
end
