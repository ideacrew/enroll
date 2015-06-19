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

  embeds_many :workflow_state_transitions, as: :transitional

  delegate :hbx_id, :hbx_id=, to: :person, allow_nil: true

  accepts_nested_attributes_for :person, :workflow_state_transitions

  after_initialize :initial_transition

  validates_presence_of :npn, :provider_kind
  validates :npn, uniqueness: true
  validates :provider_kind,
    allow_blank: false,
    inclusion: { in: PROVIDER_KINDS, message: "%{value} is not a valid provider kind" }

  scope :active,      ->{ where(aasm_state: "active") }
  scope :inactive,    ->{ any_in(aasm_state: ["denied", "decertified"]) }
  scope :denied,      ->{ where(aasm_state: "denied") }
  scope :decertified, ->{ where(aasm_state: "decertified") }


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
    def find(broker_role_id)
      Person.where("broker_role._id" => broker_role_id).first.broker_role unless broker_role_id.blank?
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

    def find_by_broker_agency_profile(profile)
      return unless profile.is_a? BrokerAgencyProfile
      list_brokers(Person.where("broker_role.broker_agency_profile_id" => profile._id))
    end
  end

  aasm do
    state :applicant, initial: true
    state :active
    state :denied
    state :decertified

    event :approve, :after => :record_transition do
      transitions from: :applicant, to: :active
    end

    event :deny, :after => :record_transition  do
      transitions from: :applicant, to: :denied
    end

    event :decertify, :after => :record_transition  do
      transitions from: :active, to: :decertified
    end
  end

private

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


end
