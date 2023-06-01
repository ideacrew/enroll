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
      let!(:silver_01) { FactoryBot.create(:benefit_markets_products_health_products_health_product, :silver, hios_id: '41842ME12345S-01', csr_variant_id: '01') }
      let!(:silver_02) { FactoryBot.create(:benefit_markets_products_health_products_health_product, :silver, hios_id: '41842ME12345S-02', csr_variant_id: '02') }
      let!(:silver_03) { FactoryBot.create(:benefit_markets_products_health_products_health_product, :silver, hios_id: '41842ME12345S-03', csr_variant_id: '03') }
      let!(:silver_04) { FactoryBot.create(:benefit_markets_products_health_products_health_product, :silver, hios_id: '41842ME12345S-04', csr_variant_id: '04') }
      let!(:silver_05) { FactoryBot.create(:benefit_markets_products_health_products_health_product, :silver, hios_id: '41842ME12345S-05', csr_variant_id: '05') }
      let!(:silver_06) { FactoryBot.create(:benefit_markets_products_health_products_health_product, :silver, hios_id: '41842ME12345S-06', csr_variant_id: '06') }

      let!(:gold_01) { FactoryBot.create(:benefit_markets_products_health_products_health_product, :gold, hios_id: '41842ME12345G-01', csr_variant_id: '01') }
      let!(:gold_02) { FactoryBot.create(:benefit_markets_products_health_products_health_product, :gold, hios_id: '41842ME12345G-02', csr_variant_id: '02') }
      let!(:gold_03) { FactoryBot.create(:benefit_markets_products_health_products_health_product, :gold, hios_id: '41842ME12345G-03', csr_variant_id: '03') }

      let!(:bronze_01) { FactoryBot.create(:benefit_markets_products_health_products_health_product, :bronze, hios_id: '41842ME12345B-01', csr_variant_id: '01') }
      let!(:bronze_02) { FactoryBot.create(:benefit_markets_products_health_products_health_product, :bronze, hios_id: '41842ME12345B-02', csr_variant_id: '02') }
      let!(:bronze_03) { FactoryBot.create(:benefit_markets_products_health_products_health_product, :bronze, hios_id: '41842ME12345B-03', csr_variant_id: '03') }

      let!(:platinum_01) { FactoryBot.create(:benefit_markets_products_health_products_health_product, :platinum, hios_id: '41842ME12345P-01', csr_variant_id: '01') }
      let!(:platinum_02) { FactoryBot.create(:benefit_markets_products_health_products_health_product, :platinum, hios_id: '41842ME12345P-02', csr_variant_id: '02') }
      let!(:platinum_03) { FactoryBot.create(:benefit_markets_products_health_products_health_product, :platinum, hios_id: '41842ME12345P-03', csr_variant_id: '03') }

      let!(:catastrophic_01) { FactoryBot.create(:benefit_markets_products_health_products_health_product, :catastrophic, hios_id: '41842ME12345C-01', csr_variant_id: '01') }

      context 'by_coverage_kind_year_and_csr' do
        let(:eligible_products) { product_factory.new({ market_kind: 'individual' }).by_coverage_kind_year_and_csr('health', TimeKeeper.date_of_record.year, csr_kind: csr_kind) }

        context 'csr_kind: csr_100' do
          let(:csr_kind) { 'csr_100' }

          it 'should return [silver gold bronze platinum] products with 02 variant & catastrophic with 01 variant' do
            expect(eligible_products.pluck(:id).sort).to eq([silver_02.id, gold_02.id, bronze_02.id, platinum_02.id, catastrophic_01.id].sort)
          end
        end

        context 'csr_kind: csr_limited' do
          let(:csr_kind) { 'csr_limited' }

          it 'should return [silver gold bronze platinum] products with 03 variant & catastrophic with 01 variant' do
            expect(eligible_products.pluck(:id).sort).to eq([silver_03.id, gold_03.id, bronze_03.id, platinum_03.id, catastrophic_01.id].sort)
          end
        end

        context 'csr_kind: csr_0' do
          let(:csr_kind) { 'csr_0' }

          it 'should return [silver gold bronze platinum catastrophic] products with 01 variant' do
            expect(eligible_products.pluck(:id).sort).to eq([silver_01.id, gold_01.id, bronze_01.id, platinum_01.id, catastrophic_01.id].sort)
          end
        end

        context 'csr_kind: csr_94' do
          let(:csr_kind) { 'csr_94' }

          it 'should return [catastrophic gold bronze platinum] products with 01 variant & silver with 06 variant' do
            expect(eligible_products.pluck(:id).sort).to eq([silver_06.id, gold_01.id, bronze_01.id, platinum_01.id, catastrophic_01.id].sort)
          end
        end

        context 'csr_kind: csr_87' do
          let(:csr_kind) { 'csr_87' }

          it 'should return [catastrophic gold bronze platinum] products with 01 variant & silver with 05 variant' do
            expect(eligible_products.pluck(:id).sort).to eq([silver_05.id, gold_01.id, bronze_01.id, platinum_01.id, catastrophic_01.id].sort)
          end
        end

        context 'csr_kind: csr_73' do
          let(:csr_kind) { 'csr_73' }

          it 'should return [catastrophic gold bronze platinum] products with 01 variant & silver with 04 variant' do
            expect(eligible_products.pluck(:id).sort).to eq([silver_04.id, gold_01.id, bronze_01.id, platinum_01.id, catastrophic_01.id].sort)
          end
        end
      end

      context 'by_coverage_kind_and_year' do
        let(:eligible_products) { product_factory.new({ market_kind: 'individual' }).by_coverage_kind_and_year(coverage_kind, TimeKeeper.date_of_record.year) }

        context 'coverage_kind: health' do
          let(:coverage_kind) { 'health' }

          it 'should return health products' do
            expect(eligible_products.count).to eq 16
          end
        end

        context 'coverage_kind: dental' do
          let(:coverage_kind) { 'dental' }

          it 'should return dental products' do
            expect(eligible_products.count).to eq 0
          end
        end
      end
    end
  end
end
