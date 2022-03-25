FactoryBot.define do
  factory :products_qhp_cost_share_variance, :class => 'Products::QhpCostShareVariance' do
    association :qhp, factory: :products_qhp

    hios_plan_and_variant_id { 'hios_plan_and_variant_id' }
    plan_marketing_name { 'gold plan' }
    metal_level { 'bronze' }
    csr_variation_type { 'Standard Bronze On Exchange Plan' }
    product_id { nil }
    issuer_actuarial_value { '' }
    av_calculator_output_number { '' }
    medical_and_drug_deductibles_integrated { 'Yes' }
    medical_and_drug_max_out_of_pocket_integrated { 'Yes' }
    multiple_provider_tiers { 'Yes' }
    first_tier_utilization { '100%' }
    second_tier_utilization { '0%' }
    default_copay_in_network { '' }
    default_copay_out_of_network { '' }
    default_co_insurance_in_network { '' }
    default_co_insurance_out_of_network { '' }
    having_baby_deductible { '$6,700' }
    having_baby_co_payment { '$0' }
    having_baby_co_insurance { '$300' }
    having_baby_limit { '$60' }
    having_diabetes_deductible { '$5,400' }
    having_diabetes_copay { '$0' }
    having_diabetes_co_insurance { '$0' }
    having_diabetes_limit { '$20' }
  end
end
