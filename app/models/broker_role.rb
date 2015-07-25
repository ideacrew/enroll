class BrokerRole
  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM


  PROVIDER_KINDS = %W[broker assister]

  embedded_in :person

  field :aasm_state, type: String

  # Broker National Producer Number (unique identifier)
  field :npn, type: String
  field :broker_agency_profile_id, type: BSON::ObjectId
  field :provider_kind, type: String
  field :reason, type: String

  embeds_many :workflow_state_transitions, as: :transitional

  delegate :hbx_id, :hbx_id=, to: :person, allow_nil: true

  accepts_nested_attributes_for :person, :workflow_state_transitions

  after_initialize :initial_transition

  validates_presence_of :npn, :provider_kind

  validates :npn, 
    numericality: {only_integer: true},
    length: { minimum: 1, maximum: 10 },    
    uniqueness: true,
    allow_blank: false

  validates :provider_kind,
    allow_blank: false,
    inclusion: { in: PROVIDER_KINDS, message: "%{value} is not a valid provider kind" }


  def email_address
    return nil unless email.present?
    email.address
  end
  
  def parent
    # raise "undefined parent: Person" unless self.person?
    self.person
  end

  # belongs_to broker_agency_profile
  def broker_agency_profile=(new_broker_agency)
    if new_broker_agency.nil?
      self.broker_agency_profile_id = nil
    else
      raise ArgumentError.new("expected BrokerAgencyProfile class") unless new_broker_agency.is_a? BrokerAgencyProfile
      self.broker_agency_profile_id = new_broker_agency._id
      @broker_agency_profile = new_broker_agency
    end
  end

  def broker_agency_profile
    return @broker_agency_profile if defined? @broker_agency_profile
    @broker_agency_profile = BrokerAgencyProfile.find(broker_agency_profile_id) if has_broker_agency_profile?
  end

  def has_broker_agency_profile?
    self.broker_agency_profile_id.present?
  end

  def address=(new_address)
    parent.addresses << new_address
  end

  def address
    parent.addresses.detect { |addr| addr.kind == "work" }
  end

  def phone=(new_phone)
    parent.phones << new_phone
  end

  def phone
    parent.phones.detect { |phone| phone.kind == "work" }
  end

  def email=(new_email)
    parent.emails << new_email
  end

  def email
    parent.emails.detect { |email| email.kind == "work" }
  end

  ## Class methods
  class << self
    
    def find(id)
      return nil if id.blank?
      people = Person.where("broker_role._id" => BSON::ObjectId.from_string(id))
      people.any? ? people[0].broker_role : nil
    end

    def find_by_npn(npn_value)
      Person.where("broker_role.npn" => npn_value).first.broker_role
    end

    def list_brokers(person_list)
      person_list.reduce([]) { |brokers, person| brokers << person.broker_role }
    end

    # TODO; return as chainable Mongoid::Criteria
    def all
      # criteria = Mongoid::Criteria.new(Person)
      list_brokers(Person.exists(broker_role: true))
    end

    def first
      all.first
    end

    def last
      all.last
    end

    def find_by_broker_agency_profile(broker_agency_profile)
      raise ArgumentError.new("expected BrokerAgencyProfile") unless broker_agency_profile.is_a?(BrokerAgencyProfile)
      # list_brokers(Person.where("broker_role.broker_agency_profile_id" => profile._id))
      people = (Person.where("broker_role.broker_agency_profile_id" => broker_agency_profile.id))
      people.collect(&:broker_role)
    end

    def find_candidates_by_broker_agency_profile(broker_agency_profile)
      people = Person.where(:"broker_role.broker_agency_profile_id" => broker_agency_profile.id)\
                            .any_in(:"broker_role.aasm_state" => ["applicant", "broker_agency_pending"])
      people.collect(&:broker_role)
    end

    def find_active_by_broker_agency_profile(broker_agency_profile)
      people = Person.and(:"broker_role.broker_agency_profile_id" => broker_agency_profile.id,
                          :"broker_role.aasm_state"  => "active")
      people.collect(&:broker_role)
    end

    def find_inactive_by_broker_agency_profile(broker_agency_profile)
      people = Person.where(:"broker_role.broker_agency_profile_id" => broker_agency_profile.id)\
                            .any_in(:"broker_role.aasm_state" => ["denied", "decertified", "broker_agency_declined", "broker_agency_terminated"])
      people.collect(&:broker_role)
    end

    def agency_ids_for_active_brokers
      # people = Person.and(
      # :"broker_role.aasm_state"  => "active")

      # people.collect(&:broker_role).map(&:broker_agency_profile_id)  

      Person.collection.raw_aggregate([
        {"$match" => {"broker_role.aasm_state" => "active"}},
        {"$group" => {"_id" => "$broker_role.broker_agency_profile_id"}}
      ]).map do |record|
        record["_id"]
      end
    end
  end

  aasm do
    state :applicant, initial: true
    state :active
    state :denied
    state :decertified
    state :broker_agency_pending
    state :broker_agency_declined
    state :broker_agency_terminated

    event :approve, :after => :record_transition do
      transitions from: :applicant, to: :active, :guard => :is_primary_broker?
      transitions from: :applicant, to: :broker_agency_pending
    end

    event :broker_agency_accept, :after => :record_transition do 
      transitions from: :broker_agency_pending, to: :active
    end

    event :broker_agency_decline, :after => :record_transition do 
      transitions from: :broker_agency_pending, to: :broker_agency_declined
    end

    event :broker_agency_terminate, :after => :record_transition do 
      transitions from: :active, to: :broker_agency_terminated
    end

    event :deny, :after => :record_transition  do
      transitions from: :applicant, to: :denied
    end

    event :decertify, :after => :record_transition  do
      transitions from: :active, to: :decertified
    end

    # Attempt to achieve or return to good standing with HBX
    event :reapply, :after => :record_transition  do
      transitions from: [:applicant, :decertified, :denied, :broker_agency_declined], to: :applicant
    end  

    # Moves between broker agency organizations that don't require HBX re-certification
    event :transfer, :after => :record_transition  do
      transitions from: [:active, :broker_agency_pending, :broker_agency_terminated], to: :applicant
    end  
  end

private

  def is_primary_broker?
    return false unless broker_agency_profile
    broker_agency_profile.primary_broker_role == self
  end

  def initial_transition
    return if workflow_state_transitions.size > 0
    self.workflow_state_transitions = [WorkflowStateTransition.new(
      from_state: nil,
      to_state: aasm.to_state || "applicant",
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

  def applicant?
    aasm_state == 'applicant'
  end

  def active?
    aasm_state == 'active'
  end

  def agency_pending?
    aasm_state == 'broker_agency_pending'
  end

  def approved_or_pending?
    aasm_state == 'active'
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
end
