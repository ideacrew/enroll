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

  def certified_date
    if self.workflow_state_transitions.any?
      transition = workflow_state_transitions.detect do |transition|
        transition.from_state == 'applicant' && ( transition.to_state == 'active' || transition.to_state == 'broker_agency_pending')
      end
    end
    return unless transition
    transition.transition_at
  end

  def current_state
    aasm_state.gsub(/\_/,' ').camelcase
  end

  def email
    parent.emails.detect { |email| email.kind == "work" }
  end

  def email_address
    return nil unless email.present?
    email.address
  end

  def parent
    # raise "undefined parent: Person" unless self.person?
    self.person
  end

  def agency_pending?
    false
  end

  ## Class methods
  class << self
    
    def find(id)
      return nil if id.blank?
      people = Person.where("broker_agency_staff_roles._id" => BSON::ObjectId.from_string(id))
      people.any? ? people[0].broker_agency_staff_roles.detect{|x| x.id == id} : nil
    end
  end
  
private

  def last_state_transition_date
    if self.workflow_state_transitions.any?
      self.workflow_state_transitions.first.transition_at
    end
  end

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
