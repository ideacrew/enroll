require "rails_helper"

RSpec.describe Insured::PlanFilterHelper, :type => :helper do
  context "Shows Find Your Doctor link based on market kind" do 
    it "should return link for shop" do
      @market_kind="shop"
      expect(find_my_doctor).to eq "<a target=\"_blank\" href=\"https://dc.checkbookhealth.org/dcshop/\">Find Your Doctor</a>"
    end
    
    it "should return link for individual" do
      @market_kind="individual"
      expect(find_my_doctor).to eq "<a target=\"_blank\" href=\"https://dc.checkbookhealth.org/dc/\">Find Your Doctor</a>"
    end
  end

  context "shows estimate of your cost " do 
    it "should return link for cost estimate checkbook link" do
      @market_kind="shop"
      expect(estimate_your_costs).to eq "<a target=\"_blank\" href=\"https://dc.checkbookhealth.org/dcshop/\">Estimate_your_costs</a>"
    end

    it "should not return link for cost estimate checkbook link" do
      @market_kind="shop"
      expect(estimate_your_costs).not_to eq "<a target=\"_blank\" href=\"https://dc.health.org/dcshop/\">Estimate_your_costs</a>"
    end
  end
end