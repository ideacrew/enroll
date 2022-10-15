# frozen_string_literal: true

require 'rails_helper'
require File.join(Rails.root, 'spec/shared_contexts/benchmark_products')

RSpec.describe Operations::BenchmarkProducts::IdentifySlcsapd do
  before :all do
    DatabaseCleaner.clean
  end

  describe '#call' do
    include_context 'family with 2 family members with county_zip, rating_area & service_area'
    include_context '3 dental products with different rating_methods, different child_only_offerings and 3 health products'

    let(:input_params) do
      {
        family_id: family.id,
        effective_date: start_of_year,
        exchange_provided_code: rating_area.exchange_provided_code,
        households: [
          {
            household_id: 'a12bs6dbs1',
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

    before do
      allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate) { |_id, _start, age| age * 1.0 }
      EnrollRegistry[:enroll_app].settings(:rating_areas).stub(:item).and_return('county')
      EnrollRegistry[:service_area].settings(:service_area_model).stub(:item).and_return('county')
      benchmark_product_model = ::Operations::BenchmarkProducts::Initialize.new.call(input_params).success
      family, benchmark_product_model = ::Operations::BenchmarkProducts::IdentifyTypeOfHousehold.new.call(benchmark_product_model).success
      @benchmark_product_model = Operations::BenchmarkProducts::IdentifyRatingAndServiceAreas.new.call(
        { family: family, benchmark_product_model: benchmark_product_model }
      ).success
    end

    # 'adult_only', 'adult_and_child', 'child_only'
    context 'type_of_household: adult_and_child' do
      before do
        @result = ::Operations::BenchmarkProducts::IdentifySlcsapd.new.call(
          { family: family, benchmark_product_model: @benchmark_product_model, household_params: @benchmark_product_model.households.first.to_h }
        )
      end

      it 'return success with dental information' do
        expect(@result.success[:dental_product_hios_id]).not_to be_nil
        expect(@result.success[:dental_product_id]).not_to be_nil
        expect(@result.success[:dental_rating_method]).not_to be_nil
        expect(@result.success[:dental_ehb_apportionment_for_pediatric_dental]).not_to be_nil
        expect(@result.success[:household_dental_benchmark_ehb_premium]).not_to be_nil
      end
    end

    context 'type_of_household: child_only' do
      before do
        household_params = @benchmark_product_model.households.first.to_h
        household_params.merge!({ type_of_household: 'child_only' })
        @result = ::Operations::BenchmarkProducts::IdentifySlcsapd.new.call(
          { family: family, benchmark_product_model: @benchmark_product_model, household_params: household_params }
        )
      end

      it 'return success with dental information' do
        expect(@result.success[:dental_product_hios_id]).not_to be_nil
        expect(@result.success[:dental_product_id]).not_to be_nil
        expect(@result.success[:dental_rating_method]).not_to be_nil
        expect(@result.success[:dental_ehb_apportionment_for_pediatric_dental]).not_to be_nil
        expect(@result.success[:household_dental_benchmark_ehb_premium]).not_to be_nil
      end
    end

    context 'with all Family-Tier Rates' do
      before do
        ::BenefitMarkets::Products::DentalProducts::DentalProduct.each do |dental|
          dental.update_attributes!(rating_method: 'Family-Tier Rates')
        end
        household_params = @benchmark_product_model.households.first.to_h
        household_params.merge!({ type_of_household: 'child_only' })
        household_params[:members][0][:relationship_with_primary] = 'child'
        household_params[:members][1][:relationship_with_primary] = 'child'
        @result = ::Operations::BenchmarkProducts::IdentifySlcsapd.new.call(
          { family: family, benchmark_product_model: @benchmark_product_model, household_params: household_params }
        )
      end

      it 'return success with dental information' do
        expect(@result.success[:dental_product_hios_id]).not_to be_nil
        expect(@result.success[:dental_product_id]).not_to be_nil
        expect(@result.success[:dental_rating_method]).not_to be_nil
        expect(@result.success[:dental_ehb_apportionment_for_pediatric_dental]).not_to be_nil
        expect(@result.success[:household_dental_benchmark_ehb_premium]).not_to be_nil
      end
    end

    context 'No Dental Products' do
      before do
        ::BenefitMarkets::Products::DentalProducts::DentalProduct.each do |dental_pro|
          dental_pro.update_attributes!(benefit_market_kind: :aca_shop)
        end
        @result = ::Operations::BenchmarkProducts::IdentifySlcsapd.new.call(
          { family: family, benchmark_product_model: @benchmark_product_model, household_params: @benchmark_product_model.households.first.to_h }
        )
      end

      it 'return false with message' do
        expect(@result.failure).to match(/Could Not find any Dental Products for the given criteria/)
      end
    end
  end

  describe "with more than 3 children", dbclean: :around_each do
    include_context "family with 5 family members"
    include_context '3 dental products with different rating_methods, different child_only_offerings and 3 health products'

    let(:input_params) do
      {
        family_id: family.id,
        effective_date: start_of_year,
        exchange_provided_code: rating_area.exchange_provided_code,
        households: [
          {
            household_id: 'a12bs6dbs1',
            members: [
              {
                family_member_id: family_member1.id,
                relationship_with_primary: 'self'
              },
              {
                family_member_id: family_member2.id,
                relationship_with_primary: 'child'
              },
              {
                family_member_id: family_member3.id,
                relationship_with_primary: 'child'
              },
              {
                family_member_id: family_member4.id,
                relationship_with_primary: 'child'
              },
              {
                family_member_id: family_member5.id,
                relationship_with_primary: 'child'
              }
            ]
          }
        ]
      }
    end

    before do
      allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate) { |_id, _start, age| age * 1.0 }
      EnrollRegistry[:enroll_app].settings(:rating_areas).stub(:item).and_return('county')
      EnrollRegistry[:service_area].settings(:service_area_model).stub(:item).and_return('county')
      benchmark_product_model = ::Operations::BenchmarkProducts::Initialize.new.call(input_params).success
      family, benchmark_product_model = ::Operations::BenchmarkProducts::IdentifyTypeOfHousehold.new.call(benchmark_product_model).success
      @benchmark_product_model = Operations::BenchmarkProducts::IdentifyRatingAndServiceAreas.new.call(
        { family: family, benchmark_product_model: benchmark_product_model }
      ).success
    end

    context 'with non Family-Tier Rates' do
      before do
        ::BenefitMarkets::Products::DentalProducts::DentalProduct.each do |dental|
          dental.update_attributes!(rating_method: 'Age-Based Rates')
        end

        household_params = @benchmark_product_model.households.first.to_h
        household_params.merge!({ type_of_household: 'child_only' })
        household_params[:members][0][:relationship_with_primary] = 'self'
        household_params[:members][1][:relationship_with_primary] = 'child'
        household_params[:members][2][:relationship_with_primary] = 'child'
        household_params[:members][3][:relationship_with_primary] = 'child'
        household_params[:members][3][:relationship_with_primary] = 'child'

        @result = ::Operations::BenchmarkProducts::IdentifySlcsapd.new.call(
          { family: family, benchmark_product_model: @benchmark_product_model, household_params: household_params }
        )
      end

      it 'return success with dental information' do
        expect(@result.success[:dental_product_hios_id]).not_to be_nil
        expect(@result.success[:dental_product_id]).not_to be_nil
        expect(@result.success[:dental_rating_method]).not_to be_nil
        expect(@result.success[:dental_ehb_apportionment_for_pediatric_dental]).not_to be_nil
        expect(@result.success[:household_dental_benchmark_ehb_premium]).not_to be_nil
        expect(@result.success[:household_dental_benchmark_ehb_premium]).to eq 42.0
      end
    end

    context 'Adult with 4 children - one 19yo, the rest under 19' do
      let(:person1_age) { 30 }
      let(:person2_age) { 19 }
      let(:person3_age) { 2 }
      let(:person4_age) { 1 }
      let(:person5_age) { 1 }

      before do
        ::BenefitMarkets::Products::DentalProducts::DentalProduct.each do |dental|
          dental.update_attributes!(rating_method: 'Age-Based Rates')
        end

        household_params = @benchmark_product_model.households.first.to_h
        household_params.merge!({ type_of_household: 'child_only' })
        household_params[:members][0][:relationship_with_primary] = 'self'
        household_params[:members][1][:relationship_with_primary] = 'child'
        household_params[:members][2][:relationship_with_primary] = 'child'
        household_params[:members][3][:relationship_with_primary] = 'child'
        household_params[:members][3][:relationship_with_primary] = 'child'

        @result = ::Operations::BenchmarkProducts::IdentifySlcsapd.new.call(
          { family: family, benchmark_product_model: @benchmark_product_model, household_params: household_params }
        )
      end

      it 'return success with dental information' do
        expect(@result.success[:dental_product_hios_id]).not_to be_nil
        expect(@result.success[:dental_product_id]).not_to be_nil
        expect(@result.success[:dental_rating_method]).not_to be_nil
        expect(@result.success[:dental_ehb_apportionment_for_pediatric_dental]).not_to be_nil
        expect(@result.success[:household_dental_benchmark_ehb_premium]).not_to be_nil
        expect(@result.success[:household_dental_benchmark_ehb_premium]).to eq 3.0
      end
    end
  end
end
