require 'rails_helper'

module BenefitMarkets
  RSpec.describe Products::ProductFactory, type: :model, dbclean: :around_each do
    let!(:product) {FactoryBot.create(:benefit_markets_products_health_products_health_product)}
    let(:year) {product.application_period.min.year}
    let(:product_factory) {::BenefitMarkets::Products::ProductFactory}

    describe "#has_rates?" do
      it "should return true if rates are available with atleast one carrier" do
        expect(product_factory.new({date: TimeKeeper.date_of_record}).has_rates?).to eq true
      end

      it "should return false if rates are not available from all carriers" do
        expect(product_factory.new({date: TimeKeeper.date_of_record-1.year}).has_rates?).to eq false
      end
    end

    describe 'premium calculation' do
      context 'cost_for' do
        before do
          @product = product_factory.new({product_id: product.id})
        end

        it 'should return cost for coverage effective date and age' do
          expect(@product.cost_for(Date.new(TimeKeeper.date_of_record.year, 2, 1), 20)).to be 200.00
        end

        it 'should raise error if premium table is not present for given coverage effective date' do
          expect {@product.cost_for(Date.new(TimeKeeper.date_of_record.year - 1, 2, 1), 20)}.to raise_error StandardError
        end
      end

      context 'premium_table_for' do
        before do
          @product = product_factory.new({product_id: product.id})
        end

        it 'should return one for premium table present for given coverage effective date' do
          expect(@product.premium_table_for(Date.new(TimeKeeper.date_of_record.year, 2, 1)).count).to be 1
        end

        it 'should return true for premium table not present for given coverage effective date' do
          expect(@product.premium_table_for(Date.new(TimeKeeper.date_of_record.year - 1, 2, 1)).empty?).to be true
        end
      end
    end

    describe 'group products' do
      let!(:product1) {FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, metal_level_kind: :gold, csr_variant_id: '01')}
      let!(:product2) {FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, metal_level_kind: :catastrophic, csr_variant_id: '01')}
      let!(:product3) {FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, metal_level_kind: :bronze, csr_variant_id: '01')}
      let!(:product4) {FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, metal_level_kind: :silver, csr_variant_id: '05')}

      let!(:product5) {FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, metal_level_kind: :silver, csr_variant_id: '02')}
      let!(:product6) {FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, metal_level_kind: :gold, csr_variant_id: '02')}
      let!(:product7) {FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, metal_level_kind: :bronze, csr_variant_id: '02')}
      let!(:product8) {FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, metal_level_kind: :platinum, csr_variant_id: '02')}

      let!(:product9) {FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, metal_level_kind: :silver, csr_variant_id: '03')}
      let!(:product10) {FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, metal_level_kind: :gold, csr_variant_id: '03')}
      let!(:product11) {FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, metal_level_kind: :bronze, csr_variant_id: '03')}
      let!(:product12) {FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, metal_level_kind: :platinum, csr_variant_id: '03')}

      let!(:product13) {FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, metal_level_kind: :silver, csr_variant_id: '04')}
      let!(:product14) {FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, metal_level_kind: :platinum, csr_variant_id: '04')}

      let!(:product15) {FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, metal_level_kind: :silver, csr_variant_id: '06')}
      let!(:product16) {FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, metal_level_kind: :platinum, csr_variant_id: '06')}

      before do
        @products = product_factory.new({market_kind: "individual"})
      end

      context 'by_coverage_kind_year_and_csr' do
        it 'should return all default csr products' do
          expect(@products.by_coverage_kind_year_and_csr('health', TimeKeeper.date_of_record.year, csr_kind: nil)).to eq [product1,product2,product3]
        end

        it 'should return all product along with product having csr 87' do
          expect(@products.by_coverage_kind_year_and_csr('health', TimeKeeper.date_of_record.year, csr_kind: "csr_87")).to eq [product1,product2,product3,product4]
        end

        it 'should return all product along with product having csr 94' do
          expect(@products.by_coverage_kind_year_and_csr('health', TimeKeeper.date_of_record.year, csr_kind: "csr_94")).to eq [product1,product2,product3,product15]
        end

        it 'should return all product along with product having csr 100' do
          expect(@products.by_coverage_kind_year_and_csr('health', TimeKeeper.date_of_record.year, csr_kind: "csr_100")).to eq [product5,product6,product7,product8]
        end

        it 'should return all product along with product having csr limited' do
          expect(@products.by_coverage_kind_year_and_csr('health', TimeKeeper.date_of_record.year, csr_kind: "csr_limited")).to eq [product9,product10,product11,product12]
        end
      end

      context 'by_coverage_kind_and_year' do
        it 'should return health products' do
          expect(@products.by_coverage_kind_and_year('health', TimeKeeper.date_of_record.year).count).to eq 16
        end

        it 'should return deltal products' do
          expect(@products.by_coverage_kind_and_year('dental', TimeKeeper.date_of_record.year).count).to eq 0
        end
      end
    end
  end
end
