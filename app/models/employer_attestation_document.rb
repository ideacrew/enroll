class EmployerAttestationDocument < Document
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps
  include AASM

  field :aasm_state, type: String, default: "submitted"
  embedded_in :employer_attestation

  field :reason_for_rejection, type: String

  aasm do
    state :submitted, initial: true
    state :accepted
    state :rejected

    event :accept, :after => :record_transition do
      transitions from: :submitted, to: :accepted
    end

    event :reject, :after => :record_transition do
      transitions from: :submitted, to: :rejected
    end
  end
end