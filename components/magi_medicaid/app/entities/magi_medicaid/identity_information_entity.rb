# frozen_string_literal: true

module MagiMedicaid
  class IdentityInformationEntity < Dry::Struct

    attribute :encrypted_ssn, Types::String.optional
    attribute :no_ssn, Types::String.optional.meta(omittable: true)
  end
end
