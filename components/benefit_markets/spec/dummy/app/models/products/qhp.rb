class Products::Qhp
  include Mongoid::Document
  include Mongoid::Timestamps

  field :template_version, type: String
  field :issuer_id, type: String
  field :state_postal_code, type: String
  field :state_postal_name, type: String
  field :market_coverage, type: String
  field :dental_plan_only_ind, type: String
  field :tin, type: String
  field :application_id, type: String

  # Standard component - 14 chars
  field :standard_component_id, type: String
  field :plan_marketing_name, type: String

  # 10 character id
  field :hios_product_id, type: String
  field :hpid, type: String
  field :network_id, type: String
  field :service_area_id, type: String
  field :formulary_id, type: String

  # Plan attributes
  field :is_new_plan, type: String
  field :plan_type, type: String # hmo, ppo, pos, epo, indemnity
  field :metal_level, type: String
  field :unique_plan_design, type: String
  field :qhp_or_non_qhp, type: String # on_the_exchange, off_the_exchange, both
  field :insurance_plan_pregnancy_notice_req_ind, type: String
  field :is_specialist_referral_required, type: String
  field :health_care_specialist_referral_type, type: String, default: ""
  field :insurance_plan_benefit_exclusion_text, type: String
  field :ehb_percent_premium, type: String

  field :indian_plan_variation, type: String  # amount per enrollee

  # Required if small group
  field :hsa_eligibility, type: String
  field :employer_hsa_hra_contribution_indicator, type: String
  field :emp_contribution_amount_for_hsa_or_hra, type: String # required if HSA Eligible

  field :child_only_offering, type: String  # allows_adult_and_child_only, allows_adult_only, allows_child_only
  field :child_only_plan_id, type: String
  field :is_wellness_program_offered, type: String
  field :is_disease_mgmt_programs_offered, type: String, default: ""

  ## Stand alone dental
  # Dollar amount
  field :ehb_apportionment_for_pediatric_dental, type: String
  field :guaranteed_vs_estimated_rate  # guaranteed_rate, estimated_rate

  ## AV Calculator Additional Benefit Design
  field :maximum_coinsurance_for_specialty_drugs, type: String

  # 1-10
  field :max_num_days_for_charging_inpatient_copay, type: String
  field :begin_primary_care_deductible_or_coinsurance_after_set_number_copays, type: String
  field :begin_primary_care_cost_sharing_after_set_number_visits, type: String

  ## Plan Dates
  field :plan_effective_date, type: Date
  field :plan_expiration_date, type: Date
  field :active_year, type: Integer

  ## Geographic Coverage
  field :out_of_country_coverage, type: String
  field :out_of_country_coverage_description, type: String
  field :out_of_service_area_coverage, type: String
  field :out_of_service_area_coverage_description, type: String
  field :national_network, type: String

  ## URLs
  field :summary_benefit_and_coverage_url, type: String
  field :enrollment_payment_url, type: String
  field :plan_brochure, type: String

  field :plan_id, type: BSON::ObjectId

  embeds_many :qhp_benefits,
    class_name: "Products::QhpBenefit",
    cascade_callbacks: true,
    validate: true
end
