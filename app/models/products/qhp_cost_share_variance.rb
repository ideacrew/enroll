class Products::QhpCostShareVariance
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :qhp

  # Component plus variant
  field :hios_plan_and_variant_id, type: String
  field :plan_marketing_name, type: String
  field :metal_level, type: String
  field :csr_variation_type, type: String

  field :issuer_actuarial_value, type: Float
  field :av_calculator_output_number, type: Float

  field :medical_and_drug_deductibles_integrated, type: Boolean
  field :medical_and_drug_max_out_of_pocket_integrated, type: Boolean
  field :multiple_provider_tiers, type: Boolean
  field :first_tier_utilization, type: Float
  field :second_tier_utilization, type: Float

  field :default_copay_in_network, type: Money
  field :default_copay_out_of_network, type: Money
  field :default_co_insurance_in_network, type: Money
  field :default_co_insurance_out_of_network, type: Money

  ## SBC Scenario
  field :having_baby_deductible, type: Money
  field :having_baby_co_payment, type: Money
  field :having_baby_co_insurance, type: Money
  field :having_baby_limit, type: Money
  field :having_diabetes_deductible, type: Money
  field :having_diabetes_copay, type: Money
  field :having_diabetes_co_insurance, type: Money
  field :having_diabetes_limit, type: Money

  embeds_one :qhp_deductable,
    class_name: "Products::QhpDeductable",
    cascade_callbacks: true,
    validate: true

  embeds_many :qhp_maximum_out_of_pockets,
    class_name: "Products::QhpMaximumOutOfPocket",
    cascade_callbacks: true,
    validate: true

  embeds_many :qhp_service_visits,
    class_name: "Products::QhpServiceVisit",
    cascade_callbacks: true,
    validate: true

  accepts_nested_attributes_for :qhp_maximum_out_of_pockets, :qhp_service_visits


end
