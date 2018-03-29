module BenefitMarkets
  module ContributionModels
    class RelationshipPricingUnit < PricingModel
      field :discounted_above_threshold, type: Integer
      field :eligible_for_threshold_discount, type: Boolean, default: false

      validates_numericality_of :free_after_threshold, greater_than_or_equal_to: 0, allow_nil: true

      validate :threshold_provided_if_eligible

      def threshold_provided_if_eligible
        if eligible_for_threshold_discount
          if discounted_above_threshold.blank?
            errors.add(:discounted_above_threshold, "you must provide a value for the discount threshold if the relationship is eligible for discounting")
          end
        end
        true
      end
    end
  end
end
