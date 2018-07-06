require 'rails_helper'

# require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"
  # require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"

RSpec.describe ::BenefitSponsors::SponsoredBenefits::SponsoredBenefit, type: :model, :dbclean => :after_each do

  let(:site)                    { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
  let(:benefit_market)          { site.benefit_markets.first }
  let(:effective_period)        { Date.today.end_of_month.next_day..Date.today.end_of_month.next_year }
  let(:effective_period_begin)  { effective_period.min }

  let!(:benefit_market_catalog) { build(:benefit_markets_benefit_market_catalog, :with_product_packages,
    benefit_market: benefit_market,
    title: "SHOP Benefits for #{effective_period_begin.year}",
    application_period: (effective_period_begin.beginning_of_year..effective_period_begin.end_of_year))
  }

  let(:employer_organization)   { create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
  let(:benefit_sponsorship)     { BenefitSponsors::BenefitSponsorships::BenefitSponsorship.new(profile: employer_organization.employer_profile) }
  let(:open_enrollment_period)  { (effective_period_begin - 1.month)..(effective_period_begin - 1.month + 10.days) }
  let(:benefit_application)     { BenefitSponsors::BenefitApplications::BenefitApplication.new(
                                      benefit_sponsorship: benefit_sponsorship,
                                      # benefit_sponsor_catalog: benefit_sponsor_catalog,
                                      effective_period: effective_period,
                                      open_enrollment_period: open_enrollment_period,
                                      fte_count: 5,
                                      pte_count: 0,
                                      msp_count: 0
                                  ) }

  let(:service_areas)           { benefit_application.recorded_service_areas }
  let(:benefit_sponsor_catalog) { benefit_sponsorship.benefit_sponsor_catalog_for(service_areas, effective_period_begin) }

  let(:benefit_package)         { build(:benefit_sponsors_benefit_packages_benefit_package, benefit_application: benefit_application) }
  let(:product_package)         { build(:benefit_markets_products_product_package) }
  let(:sponsor_contribution)    { build(:benefit_sponsors_sponsored_benefits_sponsor_contribution) }
  let(:pricing_determinations)  { BenefitSponsors::SponsoredBenefits::PricingDetermination.new.to_a }

  let(:params) do
    {
      benefit_package: benefit_package,
      product_package: product_package,
      sponsor_contribution: sponsor_contribution,
      pricing_determinations: pricing_determinations,
    }
  end

  before { benefit_application.benefit_sponsor_catalog = benefit_sponsor_catalog }

  describe "A new SponsoredBenefit instance" do
    it { is_expected.to be_mongoid_document }
    it { is_expected.to have_fields(:product_package_id)}
    it { is_expected.to embed_one(:sponsor_contribution)}
    it { is_expected.to embed_many(:pricing_determinations)}

    context "with no arguments" do
      subject { described_class.new }

      it "should not be valid" do
        subject.validate
        expect(subject).to_not be_valid
      end
    end

    context "with no product_package" do
      subject { described_class.new(params.except(:product_package)) }

      it "should not be valid" do
        subject.validate
        expect(subject).to_not be_valid
        expect(subject.errors[:product_package].first).to match(/can't be blank/)
      end
    end

    context "with no sponsor_contribution" do
      subject { described_class.new(params.except(:sponsor_contribution)) }

      it "should not be valid" do
        subject.validate
        expect(subject).to_not be_valid
        expect(subject.errors[:sponsor_contribution].first).to match(/can't be blank/)
      end
    end

    context "with no pricing_determinations" do
      subject { described_class.new(params.except(:pricing_determinations)) }

      it "should not be valid" do
        subject.validate
        expect(subject).to_not be_valid
        expect(subject.errors[:pricing_determinations].first).to match(/can't be blank/)
      end
    end

    context "with all required arguments" do
      subject {described_class.new(params) }

      it "should be valid" do
        subject.validate
        expect(subject).to be_valid
      end

      context "and it is saved" do
        it "should persist" do
          expect(subject.save).to eq true
        end
      end
    end
  end

end
