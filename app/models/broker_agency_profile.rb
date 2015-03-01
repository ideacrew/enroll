class BrokerAgencyProfile
  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM

  embedded_in :organization

  MARKET_KINDS = %W[individual shop both]

  field :market_kind, type: String
  field :primary_broker_role_id, type: BSON::ObjectId

  field :aasm_state, type: String
  field :aasm_state_set_on, type: Date

  has_many :broker_agency_contacts, class_name: "Person", inverse_of: :broker_agency_contact

  delegate :hbx_id, to: :organization, allow_nil: true
  delegate :legal_name, :legal_name=, to: :organization, allow_nil: false
  delegate :dba, :dba=, to: :organization, allow_nil: true
  delegate :fein, :fein=, to: :organization, allow_nil: false  
  delegate :is_active, :is_active=, to: :organization, allow_nil: false  
  delegate :updated_by, :updated_by=, to: :organization, allow_nil: false  

  validates_presence_of :market_kind, :primary_broker_role_id

  validates :market_kind,
    inclusion: { in: MARKET_KINDS, message: "%{value} is not a valid market kind" },
    allow_blank: false

  validate :writing_agent_employed_by_broker

  def self.find_by_broker(search_broker)
  end

  # has_many employers
  def employer_clients
    return unless MARKET_KINDS.except("individual").include?(market_kind)
    EmployerProfile.find_by_broker_agency(self.id)
  end

  # TODO: has_many families
  def family_clients
    return unless MARKET_KINDS.except("shop").include?(market_kind)
    Family.find_by_broker_agency(self.id)
  end

  # has_one primary_broker
  def primary_broker=(new_primary_broker)
    if new_primary_broker.present?
      raise ArgumentError.new("expected BrokerRole class") unless new_primary_broker.is_a? BrokerRole
      self.primary_broker_role_id = new_primary_broker._id
    else
      primary_broker_role = nil
    end
  end

  def primary_broker
    BrokerRole.find(self.primary_broker_role_id) unless primary_broker_role_id.blank?
  end

  # has_many writing_agents
  def writing_agents
    BrokerRole.find_by_broker_agency(self)
  end

  def is_active?
    self.is_approved?
  end

  aasm do #no_direct_assignment: true do
    state :is_applicant, initial: true
    state :is_approved
    state :is_rejected
    state :is_suspended
    state :is_closed

    event :approve do
      transitions from: [:is_applicant, :is_suspended], to: :is_approved
    end

    event :reject do
      transitions from: :is_applicant, to: :is_rejected
    end

    event :suspend do
      transitions from: [:is_applicant, :is_approved], to: :is_suspended
    end

    event :close do
      transitions from: [:is_approved, :is_suspended], to: :is_closed
    end
  end

private
  def writing_agent_employed_by_broker
    if writing_agents.present? && broker_agency.present?
      unless broker_agency.writing_agents.detect(writing_agent)
        errors.add(:writing_agent, "must be broker at broker_agency")
      end
    end
  end



end
