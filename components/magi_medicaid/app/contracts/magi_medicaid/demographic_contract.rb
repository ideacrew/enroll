# frozen_string_literal: true

module MagiMedicaid
  # Demographic attributes validation contract.
  class DemographicContract < Dry::Validation::Contract

    params do
      required(:gender).maybe(:string)
      required(:dob).filled(:date)
      optional(:ethnicity).maybe(:array)
      optional(:race).maybe(:string)
    end
  end
end