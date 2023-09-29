# frozen_string_literal: true

require "rails_helper"
require "#{BenefitSponsors::Engine.root}/spec/support/benefit_sponsors_site_spec_helpers"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application"

RSpec.describe BenefitSponsors::Operations::BenefitSponsorships::ShopOsseEligibilities::RenewShopOsseEligibility,
               type: :model,
               dbclean: :after_each do
  include_context "setup benefit market with market catalogs and product packages"

  let(:site) do
    ::BenefitSponsors::SiteSpecHelpers.create_site_with_hbx_profile_and_benefit_market
  end
  let(:employer_organization) do
    FactoryBot.create(
      :benefit_sponsors_organizations_general_organization,
      :with_aca_shop_cca_employer_profile,
      site: site
    )
  end
  let(:employer_profile) { employer_organization.employer_profile }

  let!(:benefit_sponsorship) do
    sponsorship = employer_profile.add_benefit_sponsorship
    sponsorship.save!
    sponsorship
  end

  let(:current_effective_date) { Date.new(Date.today.year, 3, 1) }

  let(:catalog_eligibility) do
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

  let(:prospective_date) { TimeKeeper.date_of_record.end_of_year.next_day }
  let(:prospective_year) { prospective_date.year }
  let(:required_params) { { effective_date: prospective_date } }

  let(:evidence_value) { "false" }
  let(:service) { described_class.new }
  let(:event) { double(publish: true) }
  let(:success_event) { Dry::Monads::Success(event) }

  before do
    benefit_market.update(site_urn: "dc")
    TimeKeeper.set_date_of_record_unprotected!(current_effective_date)
    allow(EnrollRegistry).to receive(:feature_enabled?).and_return(true)
    allow(service).to receive(:event).and_return(success_event)
    catalog_eligibility
  end

  after { TimeKeeper.set_date_of_record_unprotected!(Date.today) }

  context "with input params" do
    it "should return success" do
      result = service.call(required_params)
      expect(result).to be_success
    end

    it "should create eligibility with :initial state evidence" do
      expect(renewal_benefit_market_catalog.reload.eligibilities).to be_empty
      service.call(required_params)
      expect(renewal_benefit_market_catalog.reload).to be_present
      expect(renewal_benefit_market_catalog.eligibilities).to be_present
      expect(renewal_benefit_market_catalog.eligibilities.pluck(:key)).to eq [
           :"aca_shop_osse_eligibility_#{prospective_year}"
         ]
    end
  end

  context "with invalid date" do
    let(:required_params) { { effective_date: "2024-1-1" } }

    it "should fail date validation" do
      result = service.call(required_params)
      expect(result).to be_failure
    end
  end
end
