# frozen_string_literal: true

module MagiMedicaid
  class PersonName
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :applicant, class_name: "::MagiMedicaid::Applicant", inverse_of: :name

    field :name_pfx, type: String
    field :first_name, type: String
    field :middle_name, type: String
    field :last_name, type: String
    field :name_sfx, type: String

  end
end
