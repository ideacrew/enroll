# frozen_string_literal: true

module MagiMedicaid
  class VlpDocument
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :applicant, class_name: "::MagiMedicaid::Applicant", inverse_of: :vlp_document

    field :vlp_subject, type: String
    field :alien_number, type: String
    field :i94_number, type: String
    field :visa_number, type: String
    field :passport_number, type: String
    field :sevis_id, type: String
    field :naturalization_number, type: String
    field :receipt_number, type: String
    field :citizenship_number, type: String
    field :card_number, type: String
    field :country_of_citizenship, type: String
    field :vlp_description, type: String

    # date of expiration of the document. e.g. passport / documentexpiration date
    field :expiration_date, type: DateTime
    # country which issued the document. e.g. passport issuing country
    field :issuing_country, type: String
  end
end
