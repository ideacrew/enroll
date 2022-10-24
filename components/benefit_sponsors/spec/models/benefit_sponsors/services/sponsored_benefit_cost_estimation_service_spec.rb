# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitSponsors::Services::SponsoredBenefitCostEstimationService, dbclean: :after_each do

  let(:benefit_application) { instance_double(::BenefitSponsors::BenefitApplications::BenefitApplication, :reinstated_id => nil, start_on: TimeKeeper.date_of_record) }
  let(:sponsored_benefit) { instance_double(::BenefitSponsors::SponsoredBenefits::SponsoredBenefit, :id => "reference_product_id") }
  let(:highest_cost_product) {  double(id: "highest_cost_product_id") }
  let(:reference_product) { double(id: "reference_product_id") }
  let(:is_osse_eligible) { true }

  describe ".product_for_benefits_page_employer_costs" do

    before do
      allow(benefit_application).to receive(:osse_eligible?).and_return(is_osse_eligible)
      allow(sponsored_benefit).to receive(:highest_cost_product).and_return(highest_cost_product)
      allow(sponsored_benefit).to receive(:reference_product).and_return(reference_product)
    end

    context "When sponsor osse eligible" do

      it "should return highest cost product" do
        product = subject.product_for_benefits_page_employer_costs(sponsored_benefit, benefit_application)
        expect(product).to eq highest_cost_product
      end
    end

    context "When sponsor not osse eligible" do

      let(:is_osse_eligible) { false }

      it "should return reference product" do
        product = subject.product_for_benefits_page_employer_costs(sponsored_benefit, benefit_application)
        expect(product).to eq reference_product
      end
    end
  end
end
