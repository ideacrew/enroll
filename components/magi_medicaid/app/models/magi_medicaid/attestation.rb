# frozen_string_literal: true

module MagiMedicaid
  class Attestation
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :applicant, class_name: "::MagiMedicaid::Applicant", inverse_of: :attestation

    field :is_incarcerated, type: Boolean
    field :is_disabled, type: Boolean
    field :is_self_attested_long_term_care, type: Boolean, default: false
  end
end
