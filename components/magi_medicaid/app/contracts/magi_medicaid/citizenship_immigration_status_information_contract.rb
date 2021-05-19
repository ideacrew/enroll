# frozen_string_literal: true

module MagiMedicaid
  class CitizenshipImmigrationStatusInformationContract < Dry::Validation::Contract

    params do
      required(:citizen_status).maybe(:string)
    end
  end
end