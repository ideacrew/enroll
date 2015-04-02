class Products::Qhp
  include Mongoid::Document
  include Mongoid::Timestamps

  field :template_version, type: String
  field :issuer_id, type: String
  field :state_postal_code, type: String
  field :state_postal_name, type: String
  field :market_coverage, type: String
  field :dental_plan_only_ind, type: Boolean
  field :tin, type: Integer
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
  field :is_new_plan, type: Boolean
  field :plan_type, type: String # hmo, ppo, pos, epo, indemnity
  field :metal_level, type: String
  field :unique_plan_design, type: Boolean
  field :qhp_or_non_qhp, type: String # on_the_exchange, off_the_exchange, both
  field :insurance_plan_pregnancy_notice_req_ind, type: Boolean
  field :is_specialist_referral_required, type: Boolean
  field :health_care_specialist_referral_type, type: String, default: ""
  field :insurance_plan_benefit_exclusion_text, type: String

  field :indian_plan_variation, type: String  # amount per enrollee

  # Required if small group
  field :hsa_eligibility, type: Boolean
  field :employer_hsa_hra_contribution_indicator, type: String
  field :emp_contribution_amount_for_hsa_or_hra, type: Money # required if HSA Eligible
  
  field :child_only_offering, type: String  # allows_adult_and_child_only, allows_adult_only, allows_child_only
  field :child_only_plan_id, type: String
  field :is_wellness_program_offered, type: Boolean
  field :is_disease_mgmt_programs_offered, type: String, default: ""

  ## Stand alone dental
  # Dollar amount
  field :ehb_apportionment_for_pediatric_dental, type: String
  field :guaranteed_vs_estimated_rate  # guaranteed_rate, estimated_rate

  ## AV Calculator Additional Benefit Design
  field :maximum_coinsurance_for_specialty_drugs, type: Money

  # 1-10
  field :max_num_days_for_charging_inpatient_copay, type: Integer
  field :begin_primary_care_deductible_or_coinsurance_after_set_number_copays, type: Integer
  field :begin_primary_care_cost_sharing_after_set_number_visits, type: Integer

  ## Plan Dates
  field :plan_effective_date, type: Date
  field :plan_expiration_date, type: Date

  ## Geographic Coverage
  field :out_of_country_coverage, type: Boolean
  field :out_of_country_coverage_description, type: String
  field :out_of_service_area_coverage, type: Boolean
  field :out_of_service_area_coverage_description, type: String
  field :national_network, type: Boolean

  ## URLs
  field :summary_benefit_and_coverage_url, type: String
  field :enrollment_payment_url, type: String
  field :plan_brochure, type: String

  validates_presence_of :issuer_id, :state_postal_code,
                        :standard_component_id, :plan_marketing_name, :hios_product_id, :network_id, 
                        :service_area_id, :formulary_id, :is_new_plan, :plan_type, :metal_level,
                        :unique_plan_design, :qhp_or_non_qhp, :insurance_plan_pregnancy_notice_req_ind, 
                        :is_specialist_referral_required, :hsa_eligibility, :emp_contribution_amount_for_hsa_or_hra,
                        :child_only_offering, :is_wellness_program_offered, :plan_effective_date,
                        :out_of_country_coverage, :out_of_service_area_coverage, :national_network,
                        :summary_benefit_and_coverage_url


  embeds_many :qhp_benefits,
    class_name: "Products::QhpBenefit",
    cascade_callbacks: true,
    validate: true

  embeds_one :qhp_cost_share_variance,
    class_name: "Products::QhpCostShareVariance",
    cascade_callbacks: true,
    validate: true

  accepts_nested_attributes_for :qhp_benefits, :qhp_cost_share_variance

  index({"issuer_id" => 1})
  index({"state_postal_code" => 1})
  index({"national_network" => 1})
  index({"tin" => 1}, {sparse: true})

  index({"qhp_benefits.benefit_type_code" => 1})

end
