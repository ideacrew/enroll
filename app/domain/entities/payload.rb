require 'dry-struct'

module Types
  include Dry.Types()
end

module Entities
  class Payload < Dry::Struct
    transform_keys(&:to_sym)

    attribute :url, Types::Coercible::String
    attribute :payload, Types::Coercible::Hash
    attribute :headers, Types::Coercible::Hash
  end
end
