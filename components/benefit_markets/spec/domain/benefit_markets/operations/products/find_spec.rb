# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitMarkets::Operations::Products::Find, dbclean: :after_each do
  before do
    allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(TimeKeeper.date_of_record.year, 10, 12))
  end

  let!(:site) do
    FactoryBot.create(
      :benefit_sponsors_site, :with_benefit_market, :with_benefit_market_catalog_and_product_packages,
      :as_hbx_profile, EnrollRegistry[:enroll_app].setting(:site_key).item
    )
  end
  let(:effective_date)          { TimeKeeper.date_of_record.next_month.beginning_of_month }
  let(:product_package)         { site.benefit_markets[0].benefit_market_catalogs[0].product_packages[0] }
  let(:service_areas)           { product_package.products.map(&:service_area) }

  let(:params)                  { {effective_date: effective_date, service_areas: service_areas, product_package: product_package} }

  context 'sending required parameters' do

    it 'should find Product' do
      expect(subject.call(params).success?).to be_truthy
      expect(subject.call(params).success.first.class.to_s).to match(/BenefitMarkets::Entities::HealthProduct/)
    end
  end
end
