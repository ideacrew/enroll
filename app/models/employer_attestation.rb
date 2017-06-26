class EmployerAttestation
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps
  include AASM

  field :aasm_state, type: String, default: "unsubmitted"

  embedded_in :employer_profile
  embeds_many :employer_attestation_documents, as: :documentable
  embeds_many :workflow_state_transitions, as: :transitional

  aasm do
    state :unsubmitted, initial: true
    state :submitted
    state :pending
    state :approved
    state :denied

    event :submit, :after => :record_transition do 
      transitions from: :unsubmitted, to: :submitted
    end

    event :set_pending, :after => :record_transition do
      transitions from: :submitted, to: :pending
    end

    event :approve, :after => :record_transition do
      transitions from: [:submitted, :pending, :denied], to: :approved
    end

    event :deny, :after => :record_transition do
      transitions from: [:submitted, :pending], to: :denied
    end
  end

  def has_documents?
    self.employer_attestation_documents
  end

  private

  def record_transition
    self.workflow_state_transitions << WorkflowStateTransition.new(
      from_state: aasm.from_state,
      to_state: aasm.to_state
    )
  end
end
