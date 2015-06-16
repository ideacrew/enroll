class RelationshipBenefit
  include Mongoid::Document

  embedded_in :benefit_group

  field :relationship, type: String
  field :premium_pct, type: Float, default: 0.0
  field :employer_max_amt, type: Money
  field :offered, type: Boolean, default: true

  # Indicates whether employer offers coverage for this relationship
  def offered?
    self.offered
  end
end
