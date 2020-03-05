# frozen_string_literal: true

module BenefitMarkets
  module Validators
    module ContributionModels
      class ContributionModelContract < Dry::Validation::Contract

        params do
          required(:title).filled(:string)
          optional(:key).maybe(:symbol)
          required(:sponsor_contribution_kind).filled(:string)
          required(:contribution_calculator_kind).filled(:string)
          required(:many_simultaneous_contribution_units).filled(:bool)
          required(:product_multiplicities).array(:symbol)
          required(:contribution_units).array(:hash)
          required(:member_relationships).array(:hash)
        end

        rule(:contribution_units).each do
          if key? && value
            result = ContributionUnitContract.new.call(value)
            key.failure(text: "invalid contribution unit for contribution model", error: result.errors.to_h) if result&.failure?
          end
        end

        rule(:member_relationships).each do
          if key? && value
            result = MemberRelationshipContract.new.call(value)
            key.failure(text: "invalid member relationshp for contribution model", error: result.errors.to_h) if result&.failure?
          end
        end
      end
    end
  end
end