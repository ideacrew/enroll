# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Validators::BenchmarkProducts::BenchmarkProductContract,  dbclean: :after_each do
  let(:valid_parmas_with_family) do
    {
      family_id: BSON::ObjectId.new,
      effective_date: TimeKeeper.date_of_record,
      primary_rating_address_id: BSON::ObjectId.new,
      rating_area_id: BSON::ObjectId.new,
      exchange_provided_code: 'R-ME001',
      service_area_ids: [BSON::ObjectId.new],
      household_group_benchmark_ehb_premium: 200.90,
      households: [
        {
          household_id: 'a12bs6dbs1',
          type_of_household: 'adult_only',
          household_benchmark_ehb_premium: 200.90,
          health_product_hios_id: '123',
          health_product_id: BSON::ObjectId.new,
          health_ehb: 0.99,
          household_health_benchmark_ehb_premium: 200.90,
          health_product_covers_pediatric_dental_costs: true,
          members: [
            {
              family_member_id: BSON::ObjectId.new,
              relationship_with_primary: 'self',
              coverage_start_on: TimeKeeper.date_of_record
            }
          ]
        }
      ]
    }
  end

  # SLCSP Anonymous Calculator
  let(:valid_parmas_without_family) do
    {
      rating_address: {
        county: 'County Name',
        zip: '11111',
        state: 'ME'
      },
      effective_date: TimeKeeper.date_of_record,
      primary_rating_address_id: BSON::ObjectId.new,
      rating_area_id: BSON::ObjectId.new,
      exchange_provided_code: 'R-ME001',
      service_area_ids: [BSON::ObjectId.new],
      household_group_benchmark_ehb_premium: 200.90,
      households: [
        {
          household_id: 'a12bs6dbs1',
          type_of_household: 'adult_only',
          household_benchmark_ehb_premium: 200.90,
          health_product_hios_id: '123',
          health_product_id: BSON::ObjectId.new,
          health_ehb: 0.99,
          household_health_benchmark_ehb_premium: 200.90,
          health_product_covers_pediatric_dental_costs: true,
          members: [
            {
              relationship_with_primary: 'self',
              date_of_birth: TimeKeeper.date_of_record - 30.years,
              coverage_start_on: TimeKeeper.date_of_record
            }
          ]
        }
      ]
    }
  end

  describe '#call' do
    context 'valid params with family' do
      it 'passes validation' do
        result = subject.call(valid_parmas_with_family)
        expect(result.success?).to be_truthy
      end
    end

    context 'valid params without family' do
      it 'passes validation' do
        result = subject.call(valid_parmas_without_family)
        expect(result.success?).to be_truthy
      end
    end

    context 'including a domestic_partner' do
      let(:input_params) do
        valid_parmas_with_family[:households].first[:members].first[:relationship_with_primary] = 'domestic_partner'
        valid_parmas_with_family
      end

      it 'passes validation' do
        result = subject.call(input_params)
        expect(result.success?).to be_truthy
      end
    end

    context 'invalid params' do
      context 'no params' do
        it 'fails validation' do
          result = subject.call({})
          expect(result.failure?).to be_truthy
          expect(result.errors.to_h).not_to be_empty
        end
      end

      context 'without family without rating address' do
        let(:invalid_params) do
          valid_parmas_without_family[:rating_address] = [{}, nil].sample
          valid_parmas_without_family
        end

        it 'fails validation' do
          result = subject.call(invalid_params)
          expect(result.errors.to_h).not_to be_empty
        end
      end

      context 'invalid relationship_kind' do
        let(:invalid_params) do
          valid_parmas_with_family[:households].first[:members].first[:relationship_with_primary] = 'test'
          valid_parmas_with_family
        end

        it 'fails validation' do
          result = subject.call(invalid_params)
          expect(result.errors.to_h[:households][0][:members][0][:relationship_with_primary]).to include(/must be one of:/)
        end
      end

      context 'invalid relationship_kind' do
        let(:invalid_params) do
          valid_parmas_with_family[:households].first[:members].first[:relationship_with_primary] = 1287
          valid_parmas_with_family
        end

        it 'fails validation' do
          result = subject.call(invalid_params)
          expect(result.errors.to_h[:households][0][:members][0][:relationship_with_primary]).to include('must be a string')
        end
      end
    end
  end
end
