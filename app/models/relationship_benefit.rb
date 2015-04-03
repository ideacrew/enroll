class RelationshipBenefit
  include Mongoid::Document

  embedded_in :benefit_group

  field :relationship, type: String
  field :premium_pct, type: Integer
  field :employer_max_amt, type: Float
  field :offered, type: Boolean

  # Indicates whether employer offers coverage for this relationship
  def offered?
    self.offered
  end
end
