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

  # has_many employers
  def employer_clients
    return unless MARKET_KINDS.except("individual").include?(market_kind)
    EmployerProfile.find_by_broker_agency_profile(self.id)
  end

  # TODO: has_many families
  def family_clients
    return unless MARKET_KINDS.except("shop").include?(market_kind)
    Family.find_by_broker_agency_profile(self.id)
  end

  # has_one primary_broker_role
  def primary_broker_role=(new_primary_broker_role)
    if new_primary_broker_role.present?
      raise ArgumentError.new("expected BrokerRole class") unless new_primary_broker_role.is_a? BrokerRole
      self.primary_broker_role_id = new_primary_broker_role._id
    else
      primary_broker_role_id = nil
    end
  end

  def legal_name
    organization.legal_name
  end

  def primary_broker_role
    BrokerRole.find(self.primary_broker_role_id) unless primary_broker_role_id.blank?
  end

  # alias for brokers
  def writing_agents
    brokers
  end

  # has_many brokers
  def brokers
    BrokerRole.find_by_broker_agency_profile(self)
  end

  def market_kind=(new_market_kind)
    write_attribute(:market_kind, new_market_kind.to_s.downcase)
  end

  def is_active?
    self.is_approved?
  end

  ## Class methods
  class << self
    def list_embedded(parent_list)
      parent_list.reduce([]) { |list, parent_instance| list << parent_instance.broker_agency_profile }
    end

    # TODO; return as chainable Mongoid::Criteria
    def all
      list_embedded Organization.exists(broker_agency_profile: true).order_by([:dba]).to_a
    end

    def first
      all.first
    end

    def last
      all.last
    end

    def find(id)
      organizations = Organization.where("broker_agency_profile._id" => BSON::ObjectId.from_string(id)).to_a
      organizations.size > 0 ? organizations.first.broker_agency_profile : nil
    end

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
    # TODO: make this work when I'm not tired - Sean Carley
    if writing_agents.present?
      employers = EmployerProfile.find_by_broker_agency_profile(self)
      writing_agents.each do |broker_role|
        brokers = EmployerProfile.find_by_writing_agent(broker_role)
        unless true
          errors.add(:writing_agent, "must be broker at broker_agency")
        end
      end
    end
  end
end
