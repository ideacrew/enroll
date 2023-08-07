class BrokerAgencyStaffRole
  include Mongoid::Document
  # include MongoidSupport::AssociationProxies
  include AASM
  # include SetCurrentUser

  embedded_in :person
  field :aasm_state, type: String, default: "broker_agency_pending"
  field :reason, type: String
  field :broker_agency_profile_id, type: BSON::ObjectId
  field :benefit_sponsors_broker_agency_profile_id, type: BSON::ObjectId

  embeds_many :workflow_state_transitions, as: :transitional

  validates_presence_of :benefit_sponsors_broker_agency_profile_id

  # associated_with_one :broker_agency_profile, :benefit_sponsors_broker_agency_profile_id, "BenefitSponsors::Organizations::BrokerAgencyProfile"

  aasm do
    state :broker_agency_pending, initial: true
    state :active
    state :broker_agency_declined
    state :broker_agency_terminated

    event :broker_agency_accept, :after => [:record_transition, :send_invitation] do
      transitions from: :broker_agency_pending, to: :active
    end

    event :broker_agency_decline, :after => :record_transition do
      transitions from: :broker_agency_pending, to: :broker_agency_declined
    end

    event :broker_agency_terminate, :after => :record_transition do
      transitions from: :active, to: :broker_agency_terminated
      transitions from: :broker_agency_pending, to: :broker_agency_terminated
    end

    event :broker_agency_active, :after => :record_transition do
      transitions from: :broker_agency_terminated, to: :active
    end

    event :broker_agency_pending, :after => :record_transition do
      transitions from: :broker_agency_terminated, to: :broker_agency_pending
    end
  end

  def send_invitation
    # TODO: broker agency staff is not actively supported right now
    # Also this method call sends an employee invitation, which is bug 8028
    #Invitation.invite_broker_agency_staff!(self)
  end

  def approve
    broker_agency_accept!
  end

  def current_state
    aasm_state.humanize.titleize
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
    person
  end

  def agency_pending?
    aasm_state == "broker_agency_pending"
  end

  def is_open?
    agency_pending? || is_active?
  end

  def is_active?
    aasm_state == "active"
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

  def latest_transition_time
    return unless workflow_state_transitions.any?

    workflow_state_transitions.first.transition_at
  end

  def record_transition
    workflow_state_transitions << WorkflowStateTransition.new(from_state: aasm.from_state,
                                                              to_state: aasm.to_state,
                                                              event: aasm.current_event)
  end

end
