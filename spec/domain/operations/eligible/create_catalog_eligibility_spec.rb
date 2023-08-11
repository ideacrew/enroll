# frozen_string_literal: true

require "rails_helper"
require "#{BenefitSponsors::Engine.root}/spec/support/benefit_sponsors_site_spec_helpers"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market"

RSpec.describe Operations::Eligible::CreateCatalogEligibility,
               type: :model,
               dbclean: :after_each do
  describe ".benefit_market_catalog" do
    include_context "setup benefit market with market catalogs and product packages"

    let(:site) do
      ::BenefitSponsors::SiteSpecHelpers.create_site_with_hbx_profile_and_benefit_market
    end

    let(:required_params) do
      {
        subject: current_benefit_market_catalog.to_global_id,
        eligibility_feature: "aca_shop_osse_eligibility",
        effective_date:
          current_benefit_market_catalog.application_period.begin.to_date,
        domain_model:
          "AcaEntities::BenefitSponsors::BenefitSponsorships::BenefitSponsorship"
      }
    end

    context "Given a benefit market calog exists" do
      context "with valid params" do
        it "should create eligibility" do
          result = described_class.new.call(required_params)
          expect(result.success?).to be_truthy
          expect(result.success).to be_a_kind_of(Eligible::Eligibility)
        end
      end

      context "with invalid params" do
        let(:invalid_params) do
          {
            subject: current_benefit_market_catalog.to_global_id,
            effective_date:
              current_benefit_market_catalog.application_period.begin.to_date,
            eligibility_feature: "aca_shop_osse"
          }
        end

        it "should return failure" do
          result = described_class.new.call(invalid_params)

          expect(result.success?).to be_falsey
          expect(result.failure).to include("domain model missing")
          expect(result.failure).to include(
            "unable to find feature: aca_shop_osse_#{current_benefit_market_catalog.application_period.begin.year}"
          )
        end
      end
    end
  end

  describe ".benefit_coverage_period" do
    include_context "setup benefit market with market catalogs and product packages"

    let(:coverage_year) { Date.today.year }

    let(:hbx_profile) do
      FactoryBot.create(
        :hbx_profile,
        :normal_ivl_open_enrollment,
        coverage_year: coverage_year
      )
    end

    let(:benefit_coverage_period) do
      hbx_profile.benefit_sponsorship.benefit_coverage_periods.detect do |bcp|
        (bcp.start_on.year == coverage_year) &&
          bcp.start_on > bcp.open_enrollment_start_on
      end
    end

    let(:required_params) do
      {
        subject: benefit_coverage_period.to_global_id,
        eligibility_feature: "aca_ivl_osse_eligibility",
        effective_date: benefit_coverage_period.start_on.to_date,
        domain_model:
          "AcaEntities::BenefitSponsors::BenefitSponsorships::BenefitSponsorship"
      }
    end

    context "Given a benefit coverage period exists" do
      context "with valid params" do
        it "should create eligibility" do
          result = described_class.new.call(required_params)
          expect(result.success?).to be_truthy
          expect(result.success).to be_a_kind_of(Eligible::Eligibility)
        end
      end

      context "with invalid params" do
        let(:invalid_params) do
          {
            subject: benefit_coverage_period.to_global_id,
            eligibility_feature: "aca_shop_osse",
            effective_date: benefit_coverage_period.start_on.to_date
          }
        end

        it "should return failure" do
          result = described_class.new.call(invalid_params)

          expect(result.success?).to be_falsey
          expect(result.failure).to include("domain model missing")
          expect(result.failure).to include(
            "unable to find feature: aca_shop_osse_#{benefit_coverage_period.start_on.year}"
          )
        end
      end
    end
  end
end
