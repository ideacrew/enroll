class Products::QhpBenefit
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :qhp

  EhbVarianceReasonKinds = %w[above_ehb, substituted, substantially_equal, using_alternate_benchmark,
                              other_law_regulation, additional_ehb_benefit, dental_only_plan_available]


  field :benefit_type_code, type: String
  field :is_ehb, type: String
  field :is_state_mandate, type: String
  field :is_benefit_covered, type: String  # covered or not covered
  field :service_limit, type: String
  field :quantity_limit, type: String
  field :unit_limit, type: String  # Units
  field :minimum_stay, type: String
  field :exclusion, type: String
  field :explanation, type: String

  field :ehb_variance_reason, type: String

  ## Deductable and Out of Pocket Expenses
  field :subject_to_deductible_tier_1, type: String
  field :subject_to_deductible_tier_2, type: String
  field :excluded_in_network_moop, type: String
  field :excluded_out_of_network_moop, type: String

  # validates_inclusion_of :benefit_type_code, :is_ehb, :is_state_mandate

  # Scopes
  scope :child_dental_checkup, ->{ where(benefit_type_code: 'Dental Check-Up for Children', is_benefit_covered: 'Covered') }
  scope :child_basic_dental, ->{ where(benefit_type_code: 'Basic Dental Care - Child', is_benefit_covered: 'Covered') }
  scope :child_major_dental, ->{ where(benefit_type_code: 'Major Dental Care - Child', is_benefit_covered: 'Covered') }

end
