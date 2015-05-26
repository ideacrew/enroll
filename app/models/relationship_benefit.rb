class RelationshipBenefit
  include Mongoid::Document

  embedded_in :benefit_group

  field :relationship, type: String
  field :premium_pct, type: Float
  field :employer_max_amt, type: Money
  field :offered, type: Boolean

  validates :relationship, uniqueness: true

  # Indicates whether employer offers coverage for this relationship
  def offered?
    self.offered
  end
end
