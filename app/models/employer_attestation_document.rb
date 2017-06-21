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
  def record_transition
    self.workflow_state_transitions << WorkflowStateTransition.new(
      from_state: aasm.from_state,
      to_state: aasm.to_state
    )
  end
end