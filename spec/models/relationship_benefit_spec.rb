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