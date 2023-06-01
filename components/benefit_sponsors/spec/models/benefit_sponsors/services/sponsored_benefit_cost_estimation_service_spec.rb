# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitSponsors::Services::SponsoredBenefitCostEstimationService, dbclean: :after_each do

  let(:benefit_application) { instance_double(::BenefitSponsors::BenefitApplications::BenefitApplication, :reinstated_id => nil, start_on: TimeKeeper.date_of_record) }
  let(:sponsored_benefit) { instance_double(::BenefitSponsors::SponsoredBenefits::SponsoredBenefit, :id => "reference_product_id") }
  let(:highest_cost_product) {  double(id: "highest_cost_product_id") }
  let(:reference_product) { double(id: "reference_product_id") }
  let(:is_osse_eligible) { true }

end
