class BrokerAgency
  include Mongoid::Document
  include Mongoid::Timestamps

  # include AASM

  auto_increment :hbx_id, :seed => 9999
  field :name, type: String
  field :primary_broker_id, type: BSON::ObjectId

  field :aasm_state, type: String
  field :is_active, type: Boolean, default: true

  embeds_many :contacts

  has_many :employers

  validates_presence_of :name, :primary_broker_id

  # scope :all_active_brokers, ->{ and({ kind: "broker" }, { is_active: true })}
  # scope :all_active_tpzs, ->{ and({ kind: "tpa" }, { is_active: true })}

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
    Broker.find_by_agency(self)
  end

  # has_many consumers
  def consumers
    Consumer.where(:broker_agency_id => self._id)
  end

  def is_active?
    self.is_active
  end

end
