# frozen_string_literal: true

require "rails_helper"
require "#{BenefitSponsors::Engine.root}/spec/support/benefit_sponsors_site_spec_helpers.rb"
require "#{BenefitSponsors::Engine.root}/spec/support/benefit_sponsors_product_spec_helpers.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"

RSpec.describe BenefitSponsors::Operations::BenefitSponsorCatalog::Build,
               dbclean: :after_each do
  include_context "setup benefit market with market catalogs and product packages"

  let!(:abc_organization) do
    org_id =
      BenefitSponsors::OrganizationSpecHelpers.with_aca_shop_employer_profile(
        site
      )
    BenefitSponsors::Organizations::GeneralOrganization.find(org_id)
  end

  let!(:benefit_market_catalog) { current_benefit_market_catalog }

  let!(:service_area) do
    FactoryBot.create_default :benefit_markets_locations_service_area,
                              active_year: TimeKeeper.date_of_record.year
  end

  let(:abc_profile) { abc_organization.employer_profile }
  let!(:benefit_sponsorship) do
    benefit_sponsorship = abc_profile.add_benefit_sponsorship
    benefit_sponsorship.aasm_state = :active
    benefit_sponsorship.save

    benefit_sponsorship
  end

  let(:effective_date) do
    TimeKeeper.date_of_record.next_month.beginning_of_month
  end

  describe "for organization with no applications" do
    let(:params) do
      {
        effective_date: effective_date,
        benefit_sponsorship_id: benefit_sponsorship.id
      }
    end

    let(:result) { subject.call(**params) }

    it "should be success" do
      expect(result.success?).to be_truthy
    end

    it "should create BenefitSponsorCatalog object" do
      expect(
        result.success
      ).to be_a ::BenefitMarkets::Entities::BenefitSponsorCatalog
    end
  end

  describe ".eligibilities" do
    let(:current_effective_date)  { (TimeKeeper.date_of_record + 2.months).beginning_of_month }

    let!(:catalog_eligibility) do
      catalog_eligibility =
        ::Operations::Eligible::CreateCatalogEligibility.new.call(
          {
            subject: current_benefit_market_catalog.to_global_id,
            eligibility_feature: "aca_shop_osse_eligibility",
            effective_date:
              current_benefit_market_catalog.application_period.begin.to_date,
            domain_model:
              "AcaEntities::BenefitSponsors::BenefitSponsorships::BenefitSponsorship"
          }
        )

      catalog_eligibility
    end

    let!(:sponsor_eligibility) do
      BenefitSponsors::Operations::BenefitSponsorships::ShopOsseEligibilities::CreateShopOsseEligibility.new.call(
        {
          subject: benefit_sponsorship.to_global_id,
          effective_date: effective_date,
          evidence_key: :shop_osse_evidence,
          evidence_value: "true"
        }
      )
    end

    let(:params) do
      {
        effective_date: effective_date,
        benefit_sponsorship_id: benefit_sponsorship.id
      }
    end

    context "when employer has effectuated eligibilities" do
      it "should create benefit sponsor catalog with eligibilities" do
        result = subject.call(**params)

        expect(result.success?).to be_truthy
      end
    end

    # context "when employer has granted osse eligibility" do
    #   it "should create benefit sponsor catalog with applied grants" do
    #   end
    # end
  end
end
