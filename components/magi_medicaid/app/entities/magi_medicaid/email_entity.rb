# frozen_string_literal: true

module MagiMedicaid
  class EmailEntity < Dry::Struct

    attribute :kind, Types::String.optional
    attribute :address, Types::String.optional
  end
end