# frozen_string_literal: true

module MagiMedicaid
  class PersonNameEntity < Dry::Struct

    attribute :name_pfx, Types::String.optional.meta(omittable: true)
    attribute :first_name, Types::String.optional
    attribute :middle_name, Types::String.optional.meta(omittable: true)
    attribute :last_name, Types::String.optional
    attribute :name_sfx, Types::String.optional.meta(omittable: true)
  end
end
