# frozen_string_literal: true

require 'dry-types'

Dry::Types.load_extensions(:maybe)

  # dry types
module Types
  send(:include, Dry.Types())
  include Dry::Logic

  Bson = Types.Constructor(BSON::ObjectId) { |val| BSON::ObjectId val }
end