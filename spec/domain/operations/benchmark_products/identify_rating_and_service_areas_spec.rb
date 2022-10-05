# frozen_string_literal: true

require 'rails_helper'
require File.join(Rails.root, 'spec/shared_contexts/benchmark_products')

RSpec.describe Operations::BenchmarkProducts::IdentifyRatingAndServiceAreas do
  include_context 'family with 2 family members with county_zip, rating_area & service_area'

  describe '#call' do
    let(:input_params) do
      {
        family_id: family.id,
        effective_date: start_of_year,
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
      EnrollRegistry[:enroll_app].settings(:rating_areas).stub(:item).and_return('county')
      EnrollRegistry[:service_area].settings(:service_area_model).stub(:item).and_return('county')
      benchmark_product_model = ::Operations::BenchmarkProducts::Initialize.new.call(input_params).success
      _family, @benchmark_product_model = ::Operations::BenchmarkProducts::IdentifyTypeOfHousehold.new.call(benchmark_product_model).success
    end

    context 'valid input' do
      before { @result = subject.call({ family: family, benchmark_product_model: @benchmark_product_model }) }

      it 'return success' do
        expect(@result.success).to be_a(::Entities::BenchmarkProducts::BenchmarkProduct)
        expect(@result.success.rating_area_id).to eq(rating_area.id)
        expect(@result.success.exchange_provided_code).to eq(rating_area.exchange_provided_code)
        expect(@result.success.service_area_ids).to eq([service_area.id])
      end
    end

    context 'without rating address' do
      before do
        person1.addresses.destroy_all
        @result = subject.call({ family: family, benchmark_product_model: @benchmark_product_model })
      end

      it 'return failure with message' do
        expect(@result.failure).to eq("Unable to find Rating Address for Primary Person with hbx_id: #{family.primary_person.hbx_id} of Family with id: #{family.id}")
      end
    end
  end
end
