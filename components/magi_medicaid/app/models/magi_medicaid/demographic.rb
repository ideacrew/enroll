# frozen_string_literal: true

module MagiMedicaid
  class Demographic
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :applicant, class_name: "::MagiMedicaid::Applicant", inverse_of: :identity_information

    field :gender, type: String
    field :dob, type: Date
    field :ethnicity, type: Array
    field :race, type: String
    field :is_veteran_or_active_military, type: Boolean
    field :is_vets_spouse_or_child, type: Boolean
  end
end
