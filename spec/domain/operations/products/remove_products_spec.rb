# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::Products::RemoveProducts, dbclean: :after_each do

  describe 'invalid params' do

    let(:params) do
      {}
    end

    it 'returns failure' do
      result = subject.call(params)
      expect(result.failure?).to eq true
    end
  end

  describe 'valid params' do
    let(:date) { Date.today }
    let(:hbx_profile) { FactoryBot.create(:hbx_profile) }
    let(:benefit_sponsorship) { hbx_profile.benefit_sponsorship }
    let(:benefit_coverage_period) { hbx_profile.benefit_sponsorship.benefit_coverage_periods.first }
    let!(:issuer_profile) { FactoryBot.create(:benefit_sponsors_organizations_issuer_profile) }
    let!(:issuer_profile1) { FactoryBot.create(:benefit_sponsors_organizations_issuer_profile) }
    let(:plan1) { FactoryBot.create(:benefit_markets_products_health_products_health_product, issuer_profile: issuer_profile)}
    let(:plan2) { FactoryBot.create(:benefit_markets_products_health_products_health_product, issuer_profile: issuer_profile)}
    let(:plan3) { FactoryBot.create(:benefit_markets_products_health_products_health_product, issuer_profile: issuer_profile1)}
    let(:plan4) { FactoryBot.create(:benefit_markets_products_health_products_health_product, issuer_profile: issuer_profile1)}
    let(:plan5) { FactoryBot.create(:benefit_markets_products_health_products_health_product, issuer_profile: issuer_profile1)}
    let(:plan6) { FactoryBot.create(:benefit_markets_products_health_products_health_product, issuer_profile: issuer_profile1, renewal_product_id: plan1.id)}
    let(:benefit_package) do
      FactoryBot.build(:benefit_package,
                       benefit_coverage_period: hbx_profile.benefit_sponsorship.benefit_coverage_periods.first,
                       title: "individual_health_benefits",
                       elected_premium_credit_strategy: "unassisted",
                       benefit_ids: [plan1.id, plan2.id, plan3.id, plan4.id, plan5.id])
    end

    let(:products) { BenefitMarkets::Products::Product.where(issuer_profile_id: issuer_profile.id) }
    let(:params) do
      { date: date, carrier: plan1.issuer_profile.legal_name }
    end

    before do
      benefit_package.update_attributes!(benefit_ids: [plan1.id, plan2.id, plan3.id, plan4.id, plan5.id, plan6.id])
      allow(HbxProfile).to receive(:current_hbx).and_return hbx_profile
      allow(hbx_profile).to receive(:benefit_sponsorship).and_return benefit_sponsorship
      allow(benefit_sponsorship).to receive(:current_benefit_period).and_return(benefit_coverage_period)
      allow(benefit_coverage_period).to receive(:benefit_packages).and_return([benefit_package])
      @result = subject.call(params)
    end

    it 'return success' do
      expect(@result.success?).to eq true
    end

    it 'updates benefit package benefit ids' do
      expect(benefit_package.benefit_ids).to eq([plan3.id, plan4.id, plan5.id, plan6.id])
    end

    it 'removes products' do
      products = BenefitMarkets::Products::Product.where(issuer_profile_id: issuer_profile.id)
      expect(products.count).to eq 0
    end

    it 'updates renewal product ids' do
      plan6.reload
      expect(plan6.renewal_product_id).to eq nil
    end
  end
end
