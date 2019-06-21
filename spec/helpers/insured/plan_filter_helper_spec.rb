require "rails_helper"

RSpec.describe Insured::PlanFilterHelper, :type => :helper do
  context "Shows Find Your Doctor link based on market kind" do
    it "should return link for shop" do
      @market_kind = "individual"
      @coverage_kind = "health"
      expect(find_my_doctor).to eq "<a data-toggle=\"modal\" data-target=\"#plan_match_family\" href=\"\">Find Your Doctor</a>"
    end

    it "should return link for individual" do
      @market_kind = "shop"
      @coverage_kind = "health"
      expect(find_my_doctor).to eq "<a data-toggle=\"modal\" data-target=\"#plan_match_doctor_shop\" href=\"\">Find Your Doctor</a>"
    end
  end

  context ".estimate_your_costs" do
    let(:hbx_enrollment){double("HbxEnrollment", coverage_year: TimeKeeper.date_of_record.year)}
    it "should return link for congressional employee" do
      @market_kind = "shop"
      @dc_checkbook_url = Rails.application.config.checkbook_services_congress_url + "#{hbx_enrollment.coverage_year}/"
      @coverage_kind = "health"
      expect(estimate_your_costs).to eq "<a data-toggle=\"modal\" data-target=\"#plan_match_shop\" href=\"\">Estimate Your Costs</a>"
    end

    it "should return link for non-congressional employee" do
      @market_kind = "shop"
      @coverage_kind = "health"
      @dc_checkbook_url = Settings.checkbook_services.checkbook_services_ee_url
      expect(estimate_your_costs).to eq "<a data-toggle=\"modal\" data-target=\"#plan_match_shop\" href=\"\">Estimate Your Costs</a>"
    end
  end
end