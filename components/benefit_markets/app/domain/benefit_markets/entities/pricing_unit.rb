# frozen_string_literal: true

module BenefitMarkets
  module Entities
    class PricingUnit < Dry::Struct
      transform_keys(&:to_sym)

      attribute :name,                Types::Strict::String
      attribute :display_name,        Types::Strict::String
      attribute :order,               Types::Strict::Integer

    end
  end
end