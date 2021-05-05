# frozen_string_literal: true

module MagiMedicaid
  class IdentityInformation
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :applicant, class_name: "::MagiMedicaid::Applicant", inverse_of: :identity_information

    field :encrypted_ssn, type: String
    field :no_ssn, type: String, default: '0'
  end
end
