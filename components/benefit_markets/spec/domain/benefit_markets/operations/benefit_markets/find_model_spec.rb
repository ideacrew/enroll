# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitMarkets::Operations::BenefitMarkets::FindModel, dbclean: :after_each do

  let!(:site) do
    FactoryBot.create(
      :benefit_sponsors_site, :with_benefit_market, :with_benefit_market_catalog_and_product_packages,
      :as_hbx_profile, EnrollRegistry[:enroll_app].setting(:site_key).item
    )
  end
  let!(:benefit_market) { site.benefit_markets.first }
  let(:market_kind)     { :aca_shop }
  let(:params)          { {market_kind: market_kind} }

  context 'sending required parameters' do

    it 'should find BenefitMarket instance' do
      expect(subject.call(params).success?).to be_truthy
      expect(subject.call(params).success).to be_a BenefitMarkets::BenefitMarket
    end

    it 'should return object' do
      expect(subject.call(params).success).to eq benefit_market
    end
  end
end
