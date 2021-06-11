# frozen_string_literal: true

module MagiMedicaid
  class PregnancyInformation
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :applicant, class_name: "::MagiMedicaid::Applicant", inverse_of: :pregnancy_information

    field :is_pregnant, type: Boolean
    field :is_enrolled_on_medicaid, type: Boolean
    field :is_post_partum_period, type: Boolean
    field :children_expected_count, type: Integer, default: 0
    field :pregnancy_due_on, type: Date
    field :pregnancy_end_on, type: Date
  end
end
