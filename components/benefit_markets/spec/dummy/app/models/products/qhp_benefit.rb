class Products::QhpBenefit
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :qhp

  field :benefit_type_code, type: String
  field :is_benefit_covered, type: String  # covered or not covered

  # Scopes
  scope :child_dental_checkup, ->{ where(benefit_type_code: 'Dental Check-Up for Children', is_benefit_covered: 'Covered') }
  scope :child_basic_dental, ->{ where(benefit_type_code: 'Basic Dental Care - Child', is_benefit_covered: 'Covered') }
  scope :child_major_dental, ->{ where(benefit_type_code: 'Major Dental Care - Child', is_benefit_covered: 'Covered') }
end
