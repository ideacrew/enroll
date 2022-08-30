# frozen_string_literal: true

require 'rails_helper'
require File.join(Rails.root, 'spec/shared_contexts/benchmark_products')

RSpec.describe Operations::BenchmarkProducts::IdentifySlcspWithPediatricDentalCosts, type: :model, dbclean: :after_each do
  before :all do
    DatabaseCleaner.clean
  end

  describe '#call' do
    include_context 'family with 2 family members with county_zip, rating_area & service_area'
    include_context '3 dental products with different rating_methods, different child_only_offerings and 3 health products'

    let(:one_household) do
      {
        family_id: family.id,
        effective_date: start_of_year,
        exchange_provided_code: rating_area.exchange_provided_code,
        households: [
          {
            members: [
              {
                family_member_id: family_member1.id,
                relationship_with_primary: 'self'
              },
              {
                family_member_id: family_member2.id,
                relationship_with_primary: 'spouse'
              }
            ]
          }
        ]
      }
    end

    let(:two_households) do
      {
        family_id: family.id,
        effective_date: start_of_year,
        exchange_provided_code: rating_area.exchange_provided_code,
        households: [
          {
            members: [
              {
                family_member_id: family_member1.id,
                relationship_with_primary: 'self'
              }
            ]
          },
          {
            members: [
              {
                family_member_id: family_member2.id,
                relationship_with_primary: 'spouse'
              }
            ]
          }
        ]
      }
    end

    before do
      EnrollRegistry[:atleast_one_silver_plan_donot_cover_pediatric_dental_cost].feature.stub(:is_enabled).and_return(true)
      EnrollRegistry[:atleast_one_silver_plan_donot_cover_pediatric_dental_cost].settings(start_of_year.year.to_s.to_sym).stub(:item).and_return(true)
    end

    context 'geographic_rating_area_model: single' do
      before :each do
        EnrollRegistry[:enroll_app].settings(:rating_areas).stub(:item).and_return('single')
        EnrollRegistry[:service_area].settings(:service_area_model).stub(:item).and_return('single')
      end

      context 'household_type: child_only' do
        before do
          allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate) { |_id, _start, age| age * 1.0 }
          @result = subject.call(two_households)
        end

        it 'should return success with dental and health hios_ids' do
          expect(@result.success.household_group_benchmark_ehb_premium).not_to be_nil
          expect(@result.success.households.map(&:household_benchmark_ehb_premium)).not_to include(nil)
          expect(@result.success.households.map(&:household_health_benchmark_ehb_premium)).not_to include(nil)
          expect(@result.success.households.map(&:household_dental_benchmark_ehb_premium)).not_to include(nil)
          expect(@result.success.households.map(&:dental_product_hios_id)).to eq(['48396ME0860005', '48396ME0860005'])
          expect(@result.success.households.map(&:health_product_hios_id)).to eq(['48396ME0860011', '48396ME0860011'])
        end
      end
    end

    context 'geographic_rating_area_model: county' do
      before :each do
        EnrollRegistry[:enroll_app].settings(:rating_areas).stub(:item).and_return('county')
        EnrollRegistry[:service_area].settings(:service_area_model).stub(:item).and_return('county')
      end

      context 'household_type: child_only' do
        before do
          allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate) { |_id, _start, age| age * 1.0 }
          @result = subject.call(one_household)
        end

        it 'should return success with dental_hios_id' do
          expect(@result.success).to be_a(::Entities::BenchmarkProducts::BenchmarkProduct)
          expect(@result.success.household_group_benchmark_ehb_premium).not_to be_nil
          expect(@result.success.households.map(&:household_benchmark_ehb_premium)).not_to include(nil)
          expect(@result.success.households.map(&:household_health_benchmark_ehb_premium)).not_to include(nil)
          expect(@result.success.households.map(&:household_dental_benchmark_ehb_premium)).not_to include(nil)
          expect(@result.success.households.first.dental_product_hios_id).to eq('48396ME0860005')
        end
      end

      context 'household_type: adult_and_child' do
        let(:person1_age) { 37 }

        before do
          allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate) { |_id, _start, age| age * 1.0 }
          @result = subject.call(one_household)
        end

        it 'should return success with dental_hios_id' do
          expect(@result.success).to be_a(::Entities::BenchmarkProducts::BenchmarkProduct)
          expect(@result.success.household_group_benchmark_ehb_premium).not_to be_nil
          expect(@result.success.households.map(&:household_benchmark_ehb_premium)).not_to include(nil)
          expect(@result.success.households.map(&:household_health_benchmark_ehb_premium)).not_to include(nil)
          expect(@result.success.households.map(&:household_dental_benchmark_ehb_premium)).not_to include(nil)
          expect(@result.success.households.first.dental_product_hios_id).to eq('48396ME0860007')
        end
      end

      context 'household_type: adult_only' do
        let(:person1_age) { 37 }
        let(:person2_age) { 36 }

        before do
          allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate) { |_id, _start, age| age * 1.0 }
          @result = subject.call(one_household)
        end

        it 'should return success without dental_hios_id' do
          expect(@result.success).to be_a(::Entities::BenchmarkProducts::BenchmarkProduct)
          expect(@result.success.household_group_benchmark_ehb_premium).not_to be_nil
          expect(@result.success.households.map(&:household_benchmark_ehb_premium)).not_to include(nil)
          expect(@result.success.households.map(&:household_health_benchmark_ehb_premium)).not_to include(nil)
          expect(@result.success.households.map(&:household_dental_benchmark_ehb_premium).compact).to be_empty
          expect(@result.success.households.first.dental_product_hios_id).to eq(nil)
        end
      end

      context 'household_type: adult_and_child' do
        let(:person1_age) { 37 }

        context 'silver products with covers_pediatric_dental' do
          let(:covers_pediatric_dental) { true }

          before do
            ::BenefitMarkets::Products::ProductRateCache.initialize_rate_cache!
            @result = subject.call(one_household)
          end

          it 'should return success with health_hios_id' do
            expect(@result.success).to be_a(::Entities::BenchmarkProducts::BenchmarkProduct)
            expect(@result.success.household_group_benchmark_ehb_premium).not_to be_nil
            expect(@result.success.households.map(&:household_benchmark_ehb_premium)).not_to include(nil)
            expect(@result.success.households.map(&:household_health_benchmark_ehb_premium)).not_to include(nil)
            expect(@result.success.households.map(&:household_dental_benchmark_ehb_premium)).not_to include(nil)
            expect(@result.success.households.first.health_product_hios_id).to eq('48396ME0860011')
          end
        end

        context 'silver products without covers_pediatric_dental' do
          before do
            ::BenefitMarkets::Products::ProductRateCache.initialize_rate_cache!
            @result = subject.call(one_household)
          end

          it 'should return success with health_hios_id' do
            expect(@result.success).to be_a(::Entities::BenchmarkProducts::BenchmarkProduct)
            expect(@result.success.household_group_benchmark_ehb_premium).not_to be_nil
            expect(@result.success.households.map(&:household_benchmark_ehb_premium)).not_to include(nil)
            expect(@result.success.households.map(&:household_health_benchmark_ehb_premium)).not_to include(nil)
            expect(@result.success.households.map(&:household_dental_benchmark_ehb_premium)).not_to include(nil)
            expect(@result.success.households.first.health_product_hios_id).to eq('48396ME0860013')
          end
        end
      end
    end
  end
end
