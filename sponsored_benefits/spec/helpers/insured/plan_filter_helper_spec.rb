require "rails_helper"
include Config::SiteHelper

RSpec.describe Insured::PlanFilterHelper, :type => :helper do
  context "Shows Find Your Doctor link based on market kind" do
    it "should return link for shop" do
      @market_kind="shop"
      expect(find_my_doctor).to eq "<a target=\"_blank\" href=\"#{find_your_doctor_url}\">Find Your Doctor</a>"
    end

    it "should return link for individual" do
      @market_kind="individual"
      expect(find_my_doctor).to eq "<a target=\"_blank\" href=\"https://dc.checkbookhealth.org/dc/\">Find Your Doctor</a>"
    end
  end
end
