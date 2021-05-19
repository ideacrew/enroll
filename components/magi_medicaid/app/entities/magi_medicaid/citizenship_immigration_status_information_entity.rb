# frozen_string_literal: true

module MagiMedicaid
  class CitizenshipImmigrationStatusInformationEntity < Dry::Struct

    attribute :citizen_status, Types::String.optional
  end
end
