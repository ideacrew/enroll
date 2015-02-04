class BrokerAgency
  include Mongoid::Document
  include Mongoid::Timestamps

  include AASM

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

  # has_many brokers
  def brokers
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
