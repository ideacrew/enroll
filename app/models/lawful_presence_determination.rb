class LawfulPresenceDetermination
  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM

  embedded_in :consumer_role
  field :vlp_verified_date, type: Date
  field :vlp_authority, type: String
  field :vlp_document_id, type: String
  field :citizen_status, type: String
  field :aasm_state, type: String

  aasm do
    state :verification_pending, initial: true
    state :verification_outstanding
    state :verification_successful
  end

  private
  def record_transition
    workflow_state_transitions << WorkflowStateTransition.new(
      from_state: aasm.from_state,
      to_state: aasm.to_state
    )
  end
end
