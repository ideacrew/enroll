# frozen_string_literal: true

module Entities
  module Cartafact
    class Upload < Dry::Struct
      transform_keys(&:to_sym)

      attribute :subjects,            Array
      attribute :id,                  Types::Strict::String
      attribute :type,                Types::Strict::String
      attribute :source,              Types::Strict::String
    end
  end
end