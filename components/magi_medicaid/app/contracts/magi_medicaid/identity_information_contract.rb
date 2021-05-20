# frozen_string_literal: true

module MagiMedicaid
  # Identity info validation contract.
  class IdentityInformationContract < Dry::Validation::Contract

    params do
      required(:encrypted_ssn).maybe(:string)
      required(:no_ssn).maybe(:string)
    end

    rule(:encrypted_ssn, :no_ssn) do
      key.failure(text: "ssn is missing") if values[:encrypted_ssn].blank? && values[:no_ssn] == '0'
    end
  end
end