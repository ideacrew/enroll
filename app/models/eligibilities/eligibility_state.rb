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
    embeds_many :evidence_states, class_name: "::Eligibilities::EvidenceState", cascade_callbacks: true
    embeds_many :grants, class_name: "::Eligibilities::Grant", cascade_callbacks: true

    field :eligibility_item_key, type: String
    field :document_status, type: String
    field :is_eligible, type: Boolean
    field :earliest_due_date, type: Date
    field :determined_at, type: DateTime

    accepts_nested_attributes_for :evidence_states, :grants

    # seliarizable_cv_hash for eligibility states including evidence states
    # @return [Hash] hash of eligibility states
    def serializable_cv_hash
      evidence_states_hash = if evidence_states.present?
                               evidence_states.collect do |evidence_state|
                                 Hash[
                                   evidence_state.evidence_item_key,
                                   evidence_state.serializable_cv_hash
                                 ]
                               end.reduce(:merge)
                             else
                               {}
                             end

      eligibility_state_attributes = attributes.except("_id", "updated_at", "created_at", "evidence_states", "determined_at")
      eligibility_state_attributes[:determined_at] = determined_at
      eligibility_state_attributes[:evidence_states] = evidence_states_hash

      eligibility_state_attributes
    end
  end
end
