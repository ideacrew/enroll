# frozen_string_literal: true

module Eligibilities
  # Eligibility State model
  class EligibilityState
    include Mongoid::Document
    include Mongoid::Timestamps

    ELIGIBILITY_ITEM_KEYS = %i[
      aptc_csr_credit
    ].freeze

    embedded_in :subject, class_name: "::Eligibilities::Subject"
    embeds_many :evidence_states, class_name: "::Eligibilities::EvidenceState"

    field :eligibility_item_key, type: String
    field :is_eligible, type: Boolean
    field :earliest_due_date, type: Date
    field :determined_at, type: DateTime
  end
end
