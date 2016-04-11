require 'rails_helper'

RSpec.describe "shared/plan_shoppings/_plan_visit_types.html.erb" do

  let(:qhp_service_visit_1){
    Products::QhpServiceVisit.new(
      visit_type: "visit_1",
      copay_in_network_tier_1: "30 copay",
      co_insurance_in_network_tier_1: "10% coinsurance"
      )
  }
  let(:qhp_service_visit_2){
    Products::QhpServiceVisit.new(
      visit_type: "visit_2",
      copay_in_network_tier_1: "45 copay",
      co_insurance_in_network_tier_1: "20% coinsurance"
      )
  }
  let(:qhp){ Products::QhpCostShareVariance.new(qhp_service_visits: [qhp_service_visit_1, qhp_service_visit_2]) }

  let(:visit_types){ ["visit_1", "visit_2"] }

  before :each do
    @qhps = [qhp]
    assign :visit_types, visit_types
    render partial: "shared/plan_shoppings/plan_visit_types"
  end

  it "should show your current plan on plan comparison page" do
    @qhps.each do |qhp|
      qhp.qhp_service_visits.each do |service_visit|
        expect(rendered).to match(/#{service_visit.visit_type}/m)
        expect(rendered).to match(/#{service_visit.copay_in_network_tier_1}/m)
        expect(rendered).to match(/#{service_visit.co_insurance_in_network_tier_1}/m)
      end
    end
  end
end

