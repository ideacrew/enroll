module Eligibilities
  class EvidenceState
    include Mongoid::Document
    include Mongoid::Timestamps

    EVIDENCE_ITEM_KEYS = %i[
      income_evidence
      esi_evidence
      non_esi_evidence
      aces_evidence  
    ]

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
  end
end
