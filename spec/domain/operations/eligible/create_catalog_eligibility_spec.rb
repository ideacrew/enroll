# frozen_string_literal: true

require "rails_helper"
require "#{BenefitSponsors::Engine.root}/spec/support/benefit_sponsors_site_spec_helpers"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market"

RSpec.describe Operations::Eligible::CreateCatalogEligibility,
               type: :model,
               dbclean: :after_each do
  include_context "setup benefit market with market catalogs and product packages"

  let(:site) do
    ::BenefitSponsors::SiteSpecHelpers.create_site_with_hbx_profile_and_benefit_market
  end

  let(:required_params) do
    {
      subject: current_benefit_market_catalog.to_global_id,
      eligibility_feature: "aca_shop_osse_eligibility"
    }
  end

  context "Given a valid benefit market calog exists" do
    context "with valid params" do
      it "should create eligibility configuration" do
        described_class.new.call(required_params)
      end
    end

    context "with invalid params" do
      it "should return failure" do
      end
    end
  end
end
