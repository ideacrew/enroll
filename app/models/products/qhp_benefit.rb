class Products::QhpBenefit
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :qhp

  EhbVarianceReasonKinds = %w[above_ehb, substituted, substantially_equal, using_alternate_benchmark, 
                              other_law_regulation, additional_ehb_benefit, dental_only_plan_available]


  field :benefit_type_code, type: String
  field :is_ehb, type: Boolean
  field :is_state_mandate, type: Boolean
  field :is_benefit_covered, type: Boolean  # covered or not covered
  field :service_limit, type: Boolean
  field :quantity_limit, type: Boolean
  field :unit_limit, type: Integer  # Units
  field :minimum_stay, type: String
  field :exclusion, type: String
  field :explanation, type: String

  field :ehb_variance_reason, type: String

  ## Deductable and Out of Pocket Expenses
  field :subject_to_deductible_tier_1, type: Boolean
  field :subject_to_deductible_tier_2, type: Boolean
  field :excluded_in_network_moop, type: Boolean
  field :excluded_out_of_network_moop, type: Boolean
  
  # validates_inclusion_of :benefit_type_code, :is_ehb, :is_state_mandate

end
