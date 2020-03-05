# frozen_string_literal: true

module BenefitSponsors
  module Validators
    module SponsoredBenefits
      class SponsoredBenefitContract < Dry::Validation::Contract

        params do
          required(:product_package_kind).filled(:symbol)
          required(:product_option_choice).filled(:string)
          required(:source_kind).filled(:symbol)
          required(:reference_product).filled(:hash)
          required(:sponsor_contribution).filled(:hash)
          required(:pricing_determinations).array(:hash)
        end


        rule(:reference_product) do
          if key? && value
            result = ::BenefitMarkets::Validators::Products::ProductContract.new.call(value)
            key.failure(text: "invalid reference product", error: result.errors.to_h) if result&.failure?
          end
        end

        rule(:sponsor_contribution) do
          if key? && value
            result = ::BenefitSponsors::Validators::SponsoredBenefits::SponsorContributionContract.new.call(value)
            key.failure(text: "invalid sponsor contribution", error: result.errors.to_h) if result&.failure?
          end
        end

        rule(:pricing_determinations).each do
          if key? && value
            result = ::BenefitSponsors::Validators::SponsoredBenefits::PricingDeterminationContract.new.call(value)
            key.failure(text: "invalid pricing determination tier", error: result.errors.to_h) if result&.failure?
          end
        end
      end
    end
  end
end