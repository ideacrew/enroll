# frozen_string_literal: true

require 'rails_helper'

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
  describe BusinessPolicies::IvlMarketPolicies::AcaIvlProductEligibilityPolicy, dbclean: :after_each do
    subject { BusinessPolicies::IvlMarketPolicies::AcaIvlProductEligibilityPolicy.new }

    let!(:shop_health_product) {FactoryBot.create(:benefit_markets_products_health_products_health_product, metal_level_kind: :platinum)}

    let!(:ivl_health_product) do
      FactoryBot.create(:benefit_markets_products_health_products_health_product,
                        :silver,
                        csr_variant_id: '01')
    end

    let!(:ivl_health_product) do
      FactoryBot.create(:benefit_markets_products_health_products_health_product,
                        :silver,
                        csr_variant_id: '01')
    end

    let!(:ivl_health_cat_product) do
      FactoryBot.create(:benefit_markets_products_health_products_health_product,
                        :catastrophic,
                        csr_variant_id: '01')
    end

    let!(:ivl_dental_product) {FactoryBot.create(:benefit_markets_products_dental_products_dental_product, :ivl_product)}

    context 'apply_aptc' do

      context 'for success case' do
        before :each do
          @business_policy = subject.business_policies_for(ivl_health_product, :apply_aptc)
        end

        it 'should return true when validated' do
          expect(@business_policy.is_satisfied?(ivl_health_product)).to be_truthy
        end

        it 'should not return any fail results' do
          expect(@business_policy.fail_results).to be_empty
        end

        it 'should return all rules in success_results' do
          expect(@business_policy.success_results.keys).to eq @business_policy.rules.map(&:name)
          expect(@business_policy.success_results.values.uniq).to eq ['validated successfully']
        end
      end

      context 'for failure cases' do
        context 'for market_kind' do
          before do
            @business_policy = subject.business_policies_for(shop_health_product, :apply_aptc)
          end

          it 'should return false' do
            expect(@business_policy.is_satisfied?(shop_health_product)).to be_falsy
          end

          it 'should return fail results based on market kind' do
            fail_messages = ["Market Kind of given product is #{shop_health_product.benefit_market_kind} and not aca_individual"]
            expect(@business_policy.fail_results.keys).to eq [:market_kind_eligiblity]
            expect(@business_policy.fail_results.values).to eq fail_messages
          end

          it 'should not return success results for all rules' do
            expect(@business_policy.success_results.keys).not_to eq @business_policy.rules.map(&:name)
          end
        end

        context 'for product_kind' do
          before do
            @business_policy = subject.business_policies_for(ivl_dental_product, :apply_aptc)
          end

          it 'should return false' do
            expect(@business_policy.is_satisfied?(ivl_dental_product)).to be_falsy
          end

          it 'should return fail results based on market kind' do
            fail_messages = ["The given product is of kind #{ivl_dental_product.class} and not #{ivl_health_product.class}",
                             "Metal Level of the given product is #{ivl_dental_product.metal_level_kind} and not one of the [:bronze, :silver, :gold, :platinum]"]
            expect(@business_policy.fail_results.keys).to eq [:product_kind_eligibility, :metal_level_eligibility]
            expect(@business_policy.fail_results.values).to eq fail_messages
          end

          it 'should not return success results for all rules' do
            expect(@business_policy.success_results.keys).not_to eq @business_policy.rules.map(&:name)
          end
        end

        context 'for metal_level' do
          before do
            @business_policy = subject.business_policies_for(ivl_health_cat_product, :apply_aptc)
          end

          it 'should return false' do
            expect(@business_policy.is_satisfied?(ivl_health_cat_product)).to be_falsy
          end

          it 'should return fail results based on market kind' do
            fail_messages = ["Metal Level of the given product is #{ivl_health_cat_product.metal_level_kind} and not one of the [:bronze, :silver, :gold, :platinum]"]
            expect(@business_policy.fail_results.keys).to eq [:metal_level_eligibility]
            expect(@business_policy.fail_results.values).to eq fail_messages
          end

          it 'should not return success results for all rules' do
            expect(@business_policy.success_results.keys).not_to eq @business_policy.rules.map(&:name)
          end
        end
      end

      context 'for invalid inputs' do
        it 'should return not return any business_policy when invalid data is sent' do
          @business_policy = subject.business_policies_for('bad object', :apply_aptc)
          expect(@business_policy).to be_nil
        end

        it 'should return not return any business_policy when invalid data is sent' do
          @business_policy = subject.business_policies_for(ivl_health_product, 'invalid_case')
          expect(@business_policy).to be_nil
        end
      end
    end
  end
end
