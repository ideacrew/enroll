class RelationshipBenefit
  include Mongoid::Document

  embedded_in :benefit_group

  field :relationship, type: String
  field :premium_pct, type: Integer
  field :employer_max_amt, type: Float
end
