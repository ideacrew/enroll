module BenefitSponsors
  module SponsoredBenefits
    class FixedPercentContributionLevel < ContributionLevel
      field :contribution_factor, type: Float
      validates_numericality_of :contribution_factor, greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0, allow_nil: false
    end
  end
end
