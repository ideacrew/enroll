class EmployerAttestationDocument < Document
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps
  include AASM

  field :aasm_state, type: String, default: "submitted"
  field :reason_for_rejection, type: String

  embedded_in :employer_attestation
  embeds_many :workflow_state_transitions, as: :transitional

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

  def employer_profile
    org = Organization.where(:"employer_profile.employer_attestation.employer_attestation_documents._id" => BSON::ObjectId.from_string(self.id)).first
    org.employer_profile
  end

  private 
  
  def record_transition
    self.workflow_state_transitions << WorkflowStateTransition.new(
      from_state: aasm.from_state,
      to_state: aasm.to_state
    )
  end
end