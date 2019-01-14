FactoryBot.define do
  factory :products_qhp, :class => 'Products::Qhp' do
    issuer_id "1234"
    state_postal_code "DC"
    standard_component_id "12340987"
    plan_marketing_name "gold plan"
    hios_product_id "1234"
    network_id "123"
    service_area_id "12"
    formulary_id "123"
    is_new_plan "yes"
    plan_type "test"
    metal_level "bronze"
    unique_plan_design ""
    qhp_or_non_qhp "qhp"
    insurance_plan_pregnancy_notice_req_ind "yes"
    is_specialist_referral_required "yes"
    hsa_eligibility "yes"
    emp_contribution_amount_for_hsa_or_hra "1000"
    child_only_offering "no"
    is_wellness_program_offered "yes"
    plan_effective_date "04/01/2015".to_date
    out_of_country_coverage "yes"
    out_of_service_area_coverage "yes"
    national_network "yes"
    summary_benefit_and_coverage_url "www.example.com"
  end

end
