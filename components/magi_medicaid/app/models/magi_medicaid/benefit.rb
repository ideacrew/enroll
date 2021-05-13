# frozen_string_literal: true

module MagiMedicaid
  class Benefit
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :applicant, class_name: '::MagiMedicaid::Applicant'

    field :title, type: String
    field :kind, type: String
    field :insurance_kind, type: String

    field :employer_name, type: String
    field :is_employer_sponsored, type: Boolean

    field :esi_covered, type: String
    field :is_esi_waiting_period, type: Boolean
    field :is_esi_mec_met, type: Boolean

    field :employee_cost, type: Money, default: 0.00
    field :employee_cost_frequency, type: String

    field :start_on, type: Date
    field :end_on, type: Date
    field :submitted_at, type: DateTime

    field :workflow, type: Hash, default: { }

    field :employer_id, type: String, default: ''
  end
end
