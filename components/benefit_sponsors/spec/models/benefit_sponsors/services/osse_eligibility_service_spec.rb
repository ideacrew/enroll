# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

#rspec for OsseEligibilityService
module BenefitSponsors
  RSpec.describe ::BenefitSponsors::Services::OsseEligibilityService, type: :model, :dbclean => :around_each do
    include_context "setup benefit market with market catalogs and product packages"
    before(:all) { TimeKeeper.set_date_of_record_unprotected!(Date.today) }

    let!(:site)  { FactoryBot.create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let!(:organization)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let!(:employer_profile)    { organization.employer_profile }
    let!(:benefit_sponsorship) do
      employer_profile.add_benefit_sponsorship
      employer_profile.benefit_sponsorships.first.save!
      employer_profile.active_benefit_sponsorship
    end
    let(:current_effective_date) { Date.new(Date.today.year, 3, 1) }
    let(:current_date) { current_effective_date }
    let(:params) { {osse: { current_date.year.to_s => "true", current_date.last_year.year.to_s => "false" } } }
    let(:subject) { described_class.new(employer_profile, params) }

    let(:previous_catalog_eligibility) do
      ::Operations::Eligible::CreateCatalogEligibility.new.call(
        {
          subject: current_benefit_market_catalog.to_global_id,
          eligibility_feature: "aca_shop_osse_eligibility",
          effective_date: current_benefit_market_catalog.application_period.begin.to_date,
          domain_model: "AcaEntities::BenefitSponsors::BenefitSponsorships::BenefitSponsorship"
        }
      )
    end

    let(:catalog_eligibility) do
      catalog_eligibility =
        ::Operations::Eligible::CreateCatalogEligibility.new.call(
          {
            subject: current_benefit_market_catalog.to_global_id,
            eligibility_feature: "aca_shop_osse_eligibility",
            effective_date: current_benefit_market_catalog.application_period.begin.to_date,
            domain_model: "AcaEntities::BenefitSponsors::BenefitSponsorships::BenefitSponsorship"
          }
        )

      catalog_eligibility
    end

    before do
      TimeKeeper.set_date_of_record_unprotected!(current_date)
      allow(EnrollRegistry).to receive(:feature_enabled?).and_return(true)
      previous_catalog_eligibility
      catalog_eligibility
    end

    after { TimeKeeper.set_date_of_record_unprotected!(Date.today) }

    describe "#osse_eligibility_years_for_display" do
      it "returns sorted and reversed osse eligibility years" do
        expect(subject.osse_eligibility_years_for_display).to eq(
          ::BenefitMarkets::BenefitMarketCatalog.osse_eligibility_years_for_display.sort.reverse
        )
      end
    end

    describe "#osse_status_by_year" do
      before do
        osse_eligibility_years = [current_date.year, current_date.last_year.year, current_date.next_year.year]
        allow(::BenefitMarkets::BenefitMarketCatalog).to receive(:osse_eligibility_years_for_display).and_return osse_eligibility_years
        ::BenefitSponsors::Operations::BenefitSponsorships::ShopOsseEligibilities::CreateShopOsseEligibility.new.call(
          {
            subject: benefit_sponsorship.to_global_id,
            evidence_key: :shop_osse_evidence,
            evidence_value: "true",
            effective_date: TimeKeeper.date_of_record.beginning_of_year
          }
        )
        benefit_sponsorship.reload
      end

      it "returns osse status by year" do
        result = subject.osse_status_by_year

        expect(result[current_date.last_year.year][:is_eligible]).to eq(false)
        expect(result[current_date.next_year.year][:is_eligible]).to eq(false)
        expect(result[current_date.year][:is_eligible]).to eq(true)
      end
    end

    describe "#update_osse_eligibilities_by_year" do
      it "updates osse eligibilities by year" do
        allow(subject).to receive(:store_osse_eligibility).and_return(double("eligibility", success?: true))
        result = subject.update_osse_eligibilities_by_year
        expect(result).to eq({ "Success" => [current_date.year.to_s]})
      end

      context "when the year is more than 1 year old" do
        let(:old_year) { TimeKeeper.date_of_record.year - 2 }
        let(:params_1) { {osse: { old_year.to_s => "true" } } }
        let(:subject_1) { described_class.new(employer_profile, params_1) }

        it "should not update osse eligibility" do
          result = subject_1.update_osse_eligibilities_by_year
          expect(result).to eq({ "Failure" => [old_year.to_s]})
        end
      end
    end

    describe "#store_osse_eligibility" do
      let(:create_shop_eligibility_service) do
        ::BenefitSponsors::Operations::BenefitSponsorships::ShopOsseEligibilities::CreateShopOsseEligibility.new
      end

      it "creates or terms osse eligibility" do
        allow(::BenefitSponsors::Operations::BenefitSponsorships::ShopOsseEligibilities::CreateShopOsseEligibility).to receive(:new).and_return(create_shop_eligibility_service)
        allow(create_shop_eligibility_service).to receive(:call).and_return(Dry::Monads::Success())
        result = subject.store_osse_eligibility("true", TimeKeeper.date_of_record)
        expect(result.success?).to be_truthy
      end

      it "returns Failure if operation fails" do
        result = subject.store_osse_eligibility("true", Date.today.to_s)
        expect(result.success?).to be_falsy
      end
    end
  end
end
