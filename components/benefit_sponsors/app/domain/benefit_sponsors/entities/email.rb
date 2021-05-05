# frozen_string_literal: true

module BenefitSponsors
  module Entities
    # Entity to initialize while persisting email record.
    class Email < Dry::Struct
      transform_keys(&:to_sym)

      attribute :kind, Types::String.optional
      attribute :address, Types::String.optional

    end
  end
end