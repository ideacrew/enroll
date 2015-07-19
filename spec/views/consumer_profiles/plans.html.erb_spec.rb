require 'rails_helper'

describe "consumer_profiles/plans.html.erb" do
  def new_qhp_benefit
    random_value = rand(999_999_999)
    instance_double(
      "QhpBenefit",
      find_deductible: new_qhp_service_visit(random_value),
      benefit_type_code: "BenefitTypeCode: #{random_value}"
      )
  end

  def new_qhp_service_visit(random_value)
    instance_double(
      "QhpServiceVisit",
      copay_in_network_tier_1: "CopayInNetworkTier1: #{random_value}",
      copay_out_of_network: "CopayOutOfNetwork: #{random_value}"
      )
  end

  let(:plan) { instance_double("Plan", name: "My Silly Plan") }
  let(:qhp_benefits) { [new_qhp_benefit, new_qhp_benefit] }

  context "when not waived" do
    let(:benefit_group_assignment) {double(coverage_waived?: false)}
    before :each do
      assign :plan, plan
      assign :qhp_benefits, qhp_benefits
      assign :benefit_group_assignment, benefit_group_assignment
      render "consumer_profiles/plans.html.erb"
    end

    it "should display the plan name" do
      expect(rendered).to match(/#{plan.name}/m)
    end

    it "should display each benefit with in network and out of network coverages" do
      qhp_benefits.each do |benefit|
        expect(rendered).to match(/#{benefit.benefit_type_code}.*#{benefit.find_deductible.copay_in_network_tier_1}.*#{benefit.find_deductible.copay_out_of_network}/m)
      end
    end
  end

  context "when waived" do
    let(:benefit_group_assignment) {double(coverage_waived?: true)}
    before :each do
      assign :benefit_group_assignment, benefit_group_assignment
      render "consumer_profiles/plans.html.erb"
    end

    it "should display coverage waived" do
      expect(rendered).to match /Coverage Waived/
      expect(rendered).to match /Waiver Reason/
      expect(rendered).to match /Waiver on/
    end
  end
end
