# frozen_string_literal: true

module FinancialAssistance
  module Entities
    class Income < Dry::Struct
      transform_keys(&:to_sym)

      attribute :title, Types::String.optional
      attribute :wage_type, Types::String.optional.meta(omittable: true)
      attribute :amount, Types::String.optional.meta(omittable: true)
    end
  end
end
