# frozen_string_literal: true

module MagiMedicaid
  class Income
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :applicant, class_name: '::MagiMedicaid::Applicant'

    field :title, type: String
    field :kind, as: :income_type, type: String, default: 'wages_and_salaries'
    field :wage_type, type: String
    field :hours_per_week, type: Integer
    field :amount, type: Money, default: 0.00
    field :amount_tax_exempt, type: Integer, default: 0
    field :frequency_kind, type: String
    field :start_on, type: Date
    field :end_on, type: Date
    field :is_projected, type: Boolean, default: false
    # field :tax_form, type: String
    field :employer_name, type: String
    field :employer_id, type: Integer
    field :has_property_usage_rights, type: Boolean
    field :submitted_at, type: DateTime
    field :workflow, type: Hash, default: { }

  end
end
