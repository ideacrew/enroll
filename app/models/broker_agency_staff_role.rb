class BrokerAgencyStaffRole
  include Mongoid::Document
  include MongoidSupport::AssociationProxies
  include AASM

  embedded_in :person
  field :aasm_state, type: String
  field :reason, type: String
  field :broker_agency_profile_id, type: BSON::ObjectId
  embeds_many :workflow_state_transitions, as: :transitional

  associated_with_one :broker_agency_profile, :broker_agency_profile_id, "BrokerAgencyProfile"

  validates_presence_of :broker_agency_profile_id

  accepts_nested_attributes_for :person, :workflow_state_transitions

  after_initialize :initial_transition

  aasm do
    state :broker_agency_pending, initial: true
    state :active
    state :broker_agency_declined
    state :broker_agency_terminated

    event :broker_agency_accept, :after => :record_transition do 
      transitions from: :broker_agency_pending, to: :active
    end

    event :broker_agency_decline, :after => :record_transition do 
      transitions from: :broker_agency_pending, to: :broker_agency_declined
    end

    event :broker_agency_terminate, :after => :record_transition do 
      transitions from: :active, to: :broker_agency_terminated
    end
  end

private

  def initial_transition
    return if workflow_state_transitions.size > 0
    self.workflow_state_transitions = [WorkflowStateTransition.new(
      from_state: nil,
      to_state: aasm.to_state || "broker_agency_pending",
      transition_at: Time.now.utc
    )]
  end

  def record_transition
    # byebug
    self.workflow_state_transitions << WorkflowStateTransition.new(
      from_state: aasm.from_state,
      to_state: aasm.to_state,
      transition_at: Time.now.utc
    )
  end
end
