# frozen_string_literal: true

module MagiMedicaid
  class AttestationEntity < Dry::Struct

    attribute :is_incarcerated, Types::Strict::Bool.optional.meta(omittable: true)
    attribute :is_disabled, Types::Strict::Bool.meta(omittable: true)
  end
end
