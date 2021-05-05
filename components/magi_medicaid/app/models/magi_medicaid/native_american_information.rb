# frozen_string_literal: true

module MagiMedicaid
  class NativeAmericanInformation
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :applicant, class_name: "::MagiMedicaid::Applicant", inverse_of: :native_american_information

    field :indian_tribe_member, type: Boolean
    field :tribal_id, type: String
  end
end
