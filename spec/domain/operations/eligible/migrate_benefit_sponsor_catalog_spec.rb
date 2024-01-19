# frozen_string_literal: true

require "rails_helper"
require "#{BenefitSponsors::Engine.root}/spec/support/benefit_sponsors_site_spec_helpers"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application"

RSpec.describe Operations::Eligible::MigrateBenefitSponsorCatalog,
               type: :model,
               dbclean: :around_each do

  before :all do
    DatabaseCleaner.clean
  end

  describe "benefit sponsor catalog migrations" do
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

    let(:catalog_eligibility) do
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
    end

    let(:current_effective_date) { Date.new(Date.today.year, 3, 1) }
    let(:application) do
      FactoryBot.create(
        :benefit_sponsors_benefit_application,
        :with_benefit_sponsor_catalog,
        :with_benefit_package,
        package_kind: package_kind,
        aasm_state: :active,
        benefit_sponsorship: benefit_sponsorship,
        created_at: application_created_at
      )
    end

    let(:shop_osse_eligibility) do
      ::BenefitSponsors::Operations::BenefitSponsorships::ShopOsseEligibilities::CreateShopOsseEligibility.new.call(
        {
          subject: benefit_sponsorship.to_global_id,
          evidence_key: :shop_osse_evidence,
          evidence_value: "true",
          effective_date: current_effective_date.beginning_of_year
        }
      )
    end

    let(:package_kind) { :metal_level }

    let(:create_sponsor_eligibility) do
      shop_osse_eligibility
      benefit_sponsorship.reload
      eligibility = benefit_sponsorship.eligibilities.first
      eligibility.update(created_at: eligibility_created_at)
    end

    let(:reference_product_metal) { :bronze }

    let(:update_reference_product) do
      application.benefit_packages.each do |benefit_package|
        next unless benefit_package.health_sponsored_benefit
        sponsored_benefit = benefit_package.health_sponsored_benefit
        sponsored_benefit.reference_product_id =
          sponsored_benefit
          .product_package
          .products
          .detect do |product|
            product.metal_level_kind.to_s == reference_product_metal.to_s
          end
            &.id
      end
      application.save
      application.benefit_sponsorship.save
    end

    let(:enrollments) do
      [
        double(
          eligible_child_care_subsidy: 50,
          product: double(metal_level_kind: :gold)
        )
      ]
    end

    let(:families) { [double] }

    before do
      TimeKeeper.set_date_of_record_unprotected!(current_effective_date)
      allow(EnrollRegistry).to receive(:feature_enabled?).and_return(true)
      catalog_eligibility
      application
      update_reference_product
      create_sponsor_eligibility
      allow(subject).to receive(:enrolled_families).and_return(families)
      allow(subject).to receive(:enrollments_by_package).and_return(enrollments)
    end

    after { TimeKeeper.set_date_of_record_unprotected!(Date.today) }

    context "when application created after sponsor eligibility" do
      let(:application_created_at) { DateTime.now - 5.hours }
      let(:eligibility_created_at) { DateTime.now - 10.hours }
      let(:reference_product_metal) { :gold }

      context "when sponsorship passed" do
        it "should migrate benefit sponsor catalog" do
          result = subject.call(sponsorship_id: benefit_sponsorship.to_global_id)
          expect(result).to be_success
          catalog = application.benefit_sponsor_catalog.reload
          packages = catalog.product_packages.select { |pk| pk.product_kind == :health }
          expect(packages.size).to eq 1
          product_package = packages.first
          expect(product_package.package_kind).to eq :metal_level
          expect(
            product_package.products.map(&:metal_level_kind)
          ).not_to include(:bronze)

          expect(catalog.eligibilities).to be_present
        end
      end
    end

    context "when benefit application created before osse eligibility" do
      let(:application_created_at) { DateTime.now - 10.hours }
      let(:eligibility_created_at) { DateTime.now - 5.hours }
      let(:reference_product_metal) { :gold }

      it "should fail to migrate" do
        result = subject.call(sponsorship_id: benefit_sponsorship.to_global_id)

        expect(result).to be_failure
        expect(result.failure).to eq "no applications found"
      end
    end

    context "when benefit application has non metal level product package" do
      let(:application_created_at) { DateTime.now - 5.hours }
      let(:eligibility_created_at) { DateTime.now - 10.hours }
      let(:reference_product_metal) { :gold }
      let(:package_kind) { :single_issuer }

      it "should migrate benefit sponsor catalog" do
        result = subject.call(sponsorship_id: benefit_sponsorship.to_global_id)

        expect(result).to be_failure
        expect(result.failure).to include(
          /found non metal level product package for application/
        )
      end
    end
  end

  after :all do
    DatabaseCleaner.clean
  end
end
