class PlanBenifit
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :benifit_attribute_name, type: String
  field :benifit_attribute_value, type: String
  
  embedded_in :plan
  
end