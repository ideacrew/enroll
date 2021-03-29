# frozen_string_literal: true

Dry::Validation.load_extensions(:monads)

module BenefitMarkets
  module Validators
    # Configuration values and shared rules and macros for domain model validation contracts
    class ApplicationContract < Dry::Validation::Contract


      # @!macro ruleeach
      #   Validates a nested array of $0 params
      #   @!method rule(product_packages)
      rule(:product_packages).each do
        next unless key? && value
        next if value.is_a?(::BenefitMarkets::Entities::ProductPackage)
        key.failure(text: "invalid product packages. expected a hash or product_package entity") unless value.is_a?(Hash)
        value[:contribution_models] = [] unless value[:contribution_models]
        value[:assigned_contribution_model] = nil unless value[:assigned_contribution_model]
        result = BenefitMarkets::Validators::Products::ProductPackageContract.new.call(value)
        key.failure(text: "invalid product package", error: result.errors.to_h) if result&.failure?
      end

      # @!macro ruleeach
      #   Validates a nested array of $0 params
      #   @!method rule(products)
      rule(:products).each do
        next unless key? && value
        unless value.is_a?(::BenefitMarkets::Entities::Product)
          if value.is_a?(Hash)
            contract_class = "::BenefitMarkets::Validators::Products::#{value[:kind].to_s.camelize}ProductContract".constantize
            result = contract_class.new.call(value)
            key.failure(text: "invalid product", error: result.errors.to_h) if result&.failure?
          else
            key.failure(text: "invalid products. expected a hash or product entity")
          end
        end
      end

      # @!macro ruleeach
      #   Validates a nested array of $0 params
      #   @!method rule(contribution_models)
      rule(:contribution_models).each do
        next unless key? && value
        unless value.is_a?(::BenefitMarkets::Entities::ContributionModel)
          if value.is_a?(Hash)
            result = BenefitMarkets::Validators::ContributionModels::ContributionModelContract.new.call(value)
            key.failure(text: "invalid contribution model", error: result.errors.to_h) if result&.failure?
          else
            key.failure(text: "invalid contribution models. expected a hash or contribution_model entity")
          end
        end
      end

      # @!macro ruleeach
      #   Validates a nested array of $0 params
      #   @!method rule(contribution_model)
      rule(:contribution_model) do
        if key? && value && !value.is_a?(::BenefitMarkets::Entities::ContributionModel)
          if value.is_a?(Hash)
            result = BenefitMarkets::Validators::ContributionModels::ContributionModelContract.new.call(value)
            key.failure(text: "invalid contribution model", error: result.errors.to_h) if result&.failure?
          else
            key.failure(text: "invalid contribution models. expected a hash or contribution_model entity")
          end
        end
      end

      rule(:pricing_model) do
        if key? && value
          result = BenefitMarkets::Validators::PricingModels::PricingModelContract.new.call(value)
          key.failure(text: "invalid pricing model", error: result.errors.to_h) if result&.failure?
        end
      end
    end
  end
end