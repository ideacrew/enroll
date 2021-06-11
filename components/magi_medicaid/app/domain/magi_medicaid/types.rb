# frozen_string_literal: true

require 'dry-types'

Dry::Types.load_extensions(:maybe)

# MagiMedicaid engine
module MagiMedicaid
  # dry types
  module Types
    send(:include, Dry.Types())
    include Dry::Logic

    Bson = Types.Constructor(BSON::ObjectId) { |val| BSON::ObjectId val }
  end
end
