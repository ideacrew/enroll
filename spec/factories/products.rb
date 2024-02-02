# frozen_string_literal: true

# Factory for products/plans
FactoryBot.define do
  factory :product,
          :class => 'BenefitMarkets::Products::Product' do
    title { "Clear Choice HMO Catastrophic 9450" }
    description { "" }
    product_package_kinds { [:metal_level, :single_issuer, :single_product] }
    premium_ages { { min: 14, max: 64 } }
    rating_method { "Age-Based Rates" }
    benefit_market_kind { :aca_individual }
    issuer_profile_id { BSON::ObjectId('60f5d94c2a6d4300fbedc98f') }
    application_period { { min: DateTime.parse('2024-01-01'), max: DateTime.parse('2024-12-31') } }
    deductible { "$9,450" }
    family_deductible { "$9450 per person | $18900 per group" }
    is_reference_plan_eligible { true }
    kind { :health }
    updated_at { DateTime.parse('2023-12-19 14:39:31') }
    created_at { DateTime.parse('2023-12-19 14:39:31') }
  end
end