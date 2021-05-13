# frozen_string_literal: true

module MagiMedicaid
  class Deduction
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :applicant, class_name: "::MagiMedicaid::Applicant"

    field :title, type: String
    field :kind, as: :deduction_type, type: String, default: 'alimony_paid'
    field :amount, type: Money, default: 0.00
    field :start_on, type: Date
    field :end_on, type: Date
    field :frequency_kind, type: String
    field :submitted_at, type: DateTime

    field :workflow, type: Hash, default: { }
  end
end
