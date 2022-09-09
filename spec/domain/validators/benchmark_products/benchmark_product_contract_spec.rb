# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Validators::BenchmarkProducts::BenchmarkProductContract,  dbclean: :after_each do
  let(:params) do
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
              date_of_birth: TimeKeeper.date_of_record - 30.years,
              age_on_effective_date: 30
            }
          ]
        }
      ]
    }
  end

  describe '#call' do
    context 'valid params' do
      it 'passes validation' do
        result = subject.call(params)
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

      context 'invalid relationship_kind' do
        let(:invalid_params) do
          params[:households].first[:members].first[:relationship_with_primary] = 'test'
          params
        end

        it 'fails validation' do
          result = subject.call(invalid_params)
          expect(result.errors.to_h[:households][0][:members][0][:relationship_with_primary]).to include(/must be one of:/)
        end
      end

      context 'invalid relationship_kind' do
        let(:invalid_params) do
          params[:households].first[:members].first[:relationship_with_primary] = 1287
          params
        end

        it 'fails validation' do
          result = subject.call(invalid_params)
          expect(result.errors.to_h[:households][0][:members][0][:relationship_with_primary]).to include('must be a string')
        end
      end
    end
  end
end
