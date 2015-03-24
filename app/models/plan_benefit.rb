class PlanBenefit
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :benefit_attribute_name, type: String
  field :benefit_attribute_value, type: String
  
  embedded_in :plan
  
end