class BrokerAgency
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Versioning
  include AASM

  MARKET_KINDS = %W[individual shop both]

  auto_increment :hbx_id, :seed => 9999
  field :name, type: String
  field :primary_broker_id, type: BSON::ObjectId
  field :market_kind, type: String

  field :aasm_state, type: String
  field :aasm_state_set_on, type: Date
  field :updated_by, type: String

  has_many :broker_agency_contacts, class_name: "Person", inverse_of: :broker_agency_contact
  has_many :employers

  validates_presence_of :name, :primary_broker_id, :market_kind

  validates :market_kind,
    inclusion: { in: MARKET_KINDS, message: "%{value} is not a valid market" },
    allow_blank: false

  validate :writing_agent_employed_by_broker

  # has_one primary_broker
  def primary_broker=(new_primary_broker)
    raise ArgumentError.new("expected Broker class") unless new_primary_broker.is_a? Broker
    self.primary_broker_id = new_primary_broker._id
  end

  def primary_broker
    Broker.find(self.primary_broker_id) unless primary_broker_id.blank?
  end

  # has_many writing_agents
  def writing_agents
    Broker.find_by_broker_agency(self)
  end

  # has_many consumers
  def consumers
    Consumer.where(:broker_agency_id => self._id)
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
