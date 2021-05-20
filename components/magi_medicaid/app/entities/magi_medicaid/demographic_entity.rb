# frozen_string_literal: true

module MagiMedicaid
  class DemographicEntity < Dry::Struct

    attribute :gender, Types::String.optional
    attribute :dob, Types::Date.optional
    attribute :ethnicity, Types::Array.optional.meta(omittable: true)
    attribute :race, Types::String.optional.meta(omittable: true)
  end
end
