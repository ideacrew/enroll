# frozen_string_literal: true

module MagiMedicaid
  class CitizenshipImmigrationStatusInformation
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :applicant, class_name: "::MagiMedicaid::Applicant", inverse_of: :citizenship_immigration_status_information

    field :citizen_status, type: String
    field :is_resident_post_092296, type: Boolean
  end
end
