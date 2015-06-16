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

  context "created without a premium percent" do
    let(:relationship_benefit) {RelationshipBenefit.new(**(params.except(:premium_pct)))}

    it "should default premium percent to 0" do
      expect(relationship_benefit.premium_pct).to eq 0.0
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
end
