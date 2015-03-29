class PlanBenefitsPackage
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :plan

  
  # Standard component - 14 chars
  field :hios_plan_id, type: String
  field :plan_marketing_name, type: String

  # 10 character id
  field :hios_product_id, type: String
  field :network_id
  field :service_area_id
  field :formulary_id

  # Plan attributes
  field :new_or_existing
  field :plan_type, type: String # hmo, ppo, pos, epo, indemnity
  field :level_of_coverage
  field :unique_plan_design, type: Boolean
  field :qhp_non_qhp, type: String # on_the_exchange, off_the_exchange, both
  field :notice_required_for_pregnancy, type: Boolean
  field :is_a_referral_required_for_specialist, type: Boolean
  field :specialists_requiring_a_referral, type: Array, default: []
  field :plan_level_exclusions, type: String
  field :limited_cost_sharing_plan_variation, type: String  # amount per enrollee

  # Required if small group
  field :hsa_eligible, type: Boolean
  field :hsa_hra_employer_contribution_amount, type: Money # required if HSA Eligible
  
  field :child_only_offering, type: String  # allows_adult_and_child_only, allows_adult_only, allows_child_only
  field :child_only_plan_id, type: String
  field :tobacco_wellness_program_offered, type: Boolean
  field :disease_management_programs_offered, type: Array, default: []

  ## Stand alone dental
  # Dollar amount
  field :ehb_appotionment_for_pediatric_dental
  field :guaranteed_vs_estimated_rate  # guaranteed_rate, estimated_rate


  ## AV Calculator Additional Benefit Design
  field :maximum_coinsurance_for_specialty_drugs

  # 1-10
  field :maximum_number_of_days_for_charging_an_inpatient_copay
  field :begin_primary_care_cost_sharing_after_a_set_number_of_visits
  field :begin_primary_care_deductable_coinsurance_after_a_set_number_of_copays

  ## Plan Dates
  field :plan_effective_date
  field :plan_expiration_date

  ## Geographic Coverage
  field :out_of_country_coverage, type: Boolean
  field :out_of_country_coverage_description, type: String
  field :out_of_service_area_coverage, type: Boolean
  field :out_of_service_area_coverage_description, type: String
  field :national_network, type: Boolean

  ## URLs
  field :url_for_summary_of_benefits_and_coverage
  field :url_for_enrollment_payment
  field :plan_brochure


  field :benefit, type: String
  field :ehb, type: Boolean
  field :state_mandate, type: Boolean
  field :is_this_benefit_covered, type: String  # covered or not covered
  field :quantitative_limit_on_service, type: Boolean
  field :limited_quantity, type: Integer  # Units
  field :limit_unit, type: String
  field :minimum_stay, type: String
  field :exclusions, type: String
  field :benefit_explanation, type: String

# above_ehb, substituted, substantially_equal, using_alternate_benchmark, other_law_regulation, additional_ehb_benefit, dental_only_plan_avialble
  field :ehb_variance_reason, type: String

## Deductable and Out of Pocket Expenses
  field :subject_to_deductable_tier_1, type: Boolean
  field :subject_to_deductable_tier_2, type: Boolean
  field :excluded_from_in_network_moop, type: Boolean
  field :excluded_from_out_of_network_moop, type: Boolean
  
  
end