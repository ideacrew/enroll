require 'rails_helper'

module SponsoredBenefits
  RSpec.describe BenefitMarkets::BenefitMarket, type: :model, dbclean: :around_each do

    let(:kind)        { :aca_shop }
    let(:title)       {  "DC Health Link SHOP Market" }
    let(:description) {  "Health Insurance Marketplace for District Employers and Employees" }

    let(:params) do
      {
        kind: kind,
        title: title,
        description: description,
      }
    end

    context "ability to create, validate and persist instances of this class" do
      context "with no arguments" do
        subject { described_class.new }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with no kind" do
        subject { described_class.new(params.except(:kind)) }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "with kind argument" do
        let(:shop_kind) { :aca_shop }
        let(:shop_config_klass_name) { :aca_shop }

        let!(:benefit_market) { SponsoredBenefits::BenefitMarkets::BenefitMarket.new(kind: shop_kind) }

        it "should set a kind-appropropriate configuration set" do
          expect(benefit_market.kind).to eq shop_kind
          expect(benefit_market.configuration_setting).to eq "lll"
        end
      end

      context "with all required arguments" do
        let(:valid_benefit_market)  { described_class.new(params) }

        it "all provided attributes should be set" do
          expect(valid_benefit_market.kind).to eq kind
          expect(valid_benefit_market.title).to eq title
          expect(valid_benefit_market.description).to eq description
        end

        it "should be valid" do
          valid_benefit_market.validate
          expect(valid_benefit_market).to be_valid
        end
      end
    end

    # context "benefit_market should be findable by kind" do
    #   let(:shop_kind)           { :aca_shop }
    #   let(:individual_kind)     { :aca_individual }
    #   let!(:shop_site)          { FactoryGirl.create(:sponsored_benefits_site, :with_owner_exempt_organization, :with_benefit_market, kind: shop_kind) }
    #   let!(:individual_site)    { FactoryGirl.create(:sponsored_benefits_site, :with_owner_exempt_organization, :with_benefit_market, kind: individual_kind) }

    #   let(:found_sites)         { Site.by_benefit_market_kind(shop_kind) }

    #   it "should find the shop site and only the shop" do
    #     expect(found_sites.size).to eq 1
    #     expect(found_sites.first).to eq shop_site
    #   end

    #   it "should have the queried benefit_market_kind" do
    #     expect(found_sites.first.benefit_markets.first.kind).to eq shop_kind
    #   end
    # end

  end
end
