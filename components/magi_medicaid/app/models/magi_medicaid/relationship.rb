# frozen_string_literal: true

module MagiMedicaid
  class Relationship

    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :application, class_name: "::MagiMedicaid::Application", inverse_of: :relationships

    field :kind, type: String
    field :applicant_id, type: BSON::ObjectId # predecessor or from
    field :relative_id, type: BSON::ObjectId # successor or to
  end
end
