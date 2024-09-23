# frozen_string_literal: true

module Eligibilities
  # Evidence State model
  class EvidenceState
    include Mongoid::Document
    include Mongoid::Timestamps

    EVIDENCE_ITEM_KEYS = %i[
      income_evidence
      esi_evidence
      non_esi_evidence
      aces_evidence
    ].freeze

    embedded_in :eligibility_state, class_name: '::Eligibilities::EligibilityState'

    field :evidence_item_key, type: Symbol
    field :evidence_gid, type: String
    field :subject_gid, type: String
    field :status, type: Symbol
    field :is_satisfied, type: Boolean
    field :verification_outstanding, type: Boolean
    field :due_on, type: Date
    field :visited_at, type: DateTime
    field :meta, type: Hash

    # seliarizable_cv_hash for evidence states
    # @return [Hash] hash of evidence states
    def serializable_cv_hash
      evidence_state_attributes = attributes.except("_id", "updated_at", "created_at", "visited_at", "evidence_gid")
      evidence_state_attributes[:visited_at] = visited_at
      evidence_state_attributes[:evidence_gid] = URI(evidence_gid).to_s

      evidence_state_attributes
    end
  end
end
