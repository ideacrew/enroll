# frozen_string_literal: true

module MagiMedicaid
  class EmailContract < Dry::Validation::Contract

    params do
      required(:kind).filled(:string)
      required(:address).filled(:string)
    end
  end
end