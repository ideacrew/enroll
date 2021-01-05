# frozen_string_literal: true

module BenefitSponsors
  module Validators
    module SponsoredBenefits
      # PricingDeterminationTierContract  is to validate submitted params while persisting PricingDeterminations
      class PricingDeterminationTierContract < Dry::Validation::Contract

        params do
          required(:pricing_unit_id).filled(:string)
          required(:price).filled(:float)
        end
      end
    end
  end
end