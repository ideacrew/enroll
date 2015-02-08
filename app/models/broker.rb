class Broker
  include Mongoid::Document
  include Mongoid::Timestamps

  # Broker National Producer Number (unique identifier)
  field :npn, type: String
  field :broker_agency_id, type: BSON::ObjectId

  # field :aasm_state, type: String
  # field :aasm_message, type: String
  field :is_active, type: Boolean, default: true

  delegate :hbx_id, :hbx_id=, to: :person, allow_nil: true

  validates_presence_of :npn, :broker_agency_id

  # scope :all_active_brokers, ->{ and({ kind: "broker" }, { is_active: true })}
  # scope :all_active_tpzs, ->{ and({ kind: "tpa" }, { is_active: true })}

  def parent
    raise "undefined parent: Person" unless self.person?
    self.person
  end

  # belongs_to broker_agency
  def broker_agency=(new_broker_agency)
    raise ArgumentError.new("expected BrokerAgency class") unless new_broker_agency.is_a? BrokerAgency
    self.broker_agency_id = new_broker_agency._id
  end

  def broker_agency
    BrokerAgency.find(self.broker_agency_id) if has_broker_agency?
  end

  def has_broker_agency?
    broker_agency_id.present?
  end

  def self.find_by_broker_agency(broker_agency)
    return unless broker_agency.is_a? BrokerAgency
    where(broker_agency_id: broker_agency._id)
  end

  def address
    parent.addresses.detect { |adr| adr.kind == "work" }
  end

  def phone
    parent.phones.detect { |phone| phone.kind == "work" }
  end

  def email
    parent.emails.detect { |email| email.kind == "work" }
  end

  def is_active?
    self.is_active
  end

end
