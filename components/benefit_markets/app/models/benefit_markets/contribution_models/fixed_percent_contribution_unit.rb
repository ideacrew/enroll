module BenefitMarkets
  module ContributionModels
    class FixedPercentContributionUnit < ContributionUnit
      include Mongoid::Document

      field :default_contribution_factor, type: Float

      validates_numericality_of :default_contribution_factor, greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0, allow_nil: false

      def assign_contribution_value_defaults(cv)
        super(cv)
        cv.contribution_factor = default_contribution_factor * 100
      end
    end
  end
end
