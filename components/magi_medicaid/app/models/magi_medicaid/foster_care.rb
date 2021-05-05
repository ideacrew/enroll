# frozen_string_literal: true

module MagiMedicaid
  class FosterCare
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :applicant, class_name: "::MagiMedicaid::Applicant", inverse_of: :foster_care

    field :is_former_foster_care, type: Boolean
    field :age_left_foster_care, type: Integer, default: 0
    field :foster_care_us_state, type: String
    field :had_medicaid_during_foster_care, type: Boolean
  end
end
