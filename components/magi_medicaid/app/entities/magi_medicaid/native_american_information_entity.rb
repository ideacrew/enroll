# frozen_string_literal: true

module MagiMedicaid
  class NativeAmericanInformationEntity < Dry::Struct

    attribute :indian_tribe_member, Types::Bool.optional.meta(omittable: true)
    attribute :tribal_id, Types::String.optional.meta(omittable: true)
  end
end
