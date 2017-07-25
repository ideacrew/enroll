class CompositeTierContribution
  include Mongoid::Document

  embedded_in :benefit_group

  field :composite_rating_tier, type: String
  field :employer_contribution_percent, type: Float, default: 0.0
  field :estimated_tier_premium, type: Float, default: 0.0
  field :final_tier_premium, type: Float
  field :offered, type: Boolean

  validates_inclusion_of :composite_rating_tier, in: CompositeRatingTier::NAMES, allow_blank: false
  validates_inclusion_of :employer_contribution_percent, in: (0.00..100.00), allow_blank: false

  def display_premium
    final_tier_premium.blank? ? estimated_tier_premium : final_tier_premium
  end

  def employee_contribution
    display_premium - (display_premium * contribution_factor)
  end

  def employer_contribution
    display_premium * contribution_factor
  end

  def contribution_factor
    employer_contribution_percent * 0.01
  end
end
