# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::BenchmarkProducts::Initialize do
  describe '#call' do
    let(:params) do
      {
        family_id: BSON::ObjectId.new,
        effective_date: TimeKeeper.date_of_record,
        primary_rating_address_id: BSON::ObjectId.new,
        rating_area_id: BSON::ObjectId.new,
        exchange_provided_code: 'R-ME001',
        service_area_ids: [BSON::ObjectId.new],
        group_benchmark_ehb_premium: 200.90,
        households: [
          {
            type_of_household: 'adult_only',
            household_benchmark_ehb_premium: 200.90,
            health_product_hios_id: '123',
            health_product_id: BSON::ObjectId.new,
            health_ehb: 0.99,
            total_health_benchmark_ehb_premium: 200.90,
            health_product_covers_pediatric_dental_costs: true,
            members: [
              {
                family_member_id: BSON::ObjectId.new,
                relationship_kind: 'self',
                date_of_birth: TimeKeeper.date_of_record - 30.years,
                age_on_effective_date: 30
              }
            ]
          }
        ]
      }
    end

    context 'valid params' do
      it 'should return entity object' do
        expect(subject.call(params).success).to be_a(
          ::Entities::BenchmarkProducts::BenchmarkProduct
        )
      end
    end

    context 'invalid params' do
      it 'should return errors' do
        expect(subject.call({}).failure.errors.to_h).not_to be_empty
      end
    end
  end
end
