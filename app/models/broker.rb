class Broker
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :person

  KINDS = ["broker", "tpa"]

  field :kind, type: String, default: "broker"

  # Broker National Producer Number (unique identifier)
  field :npn, type: String 

  field :hbx_assigned_id, type: String

  field :is_active, type: Boolean, default: true

  embeds_one :mailing_address, class_name: "Address", inverse_of: :broker_mailing_address

  delegate :first_name, :first_name=, to: :person, prefix: true, allow_nil: true

  # has_many :consumers
  # has_many :employers

  validates_inclusion_of :kind, in: KINDS, message: "%{value} is not a valid broker type"
  validates_presence_of :npn

  # scope :all_active_brokers, ->{ and({ kind: "broker" }, { is_active: true })}
  # scope :all_active_tpzs, ->{ and({ kind: "tpa" }, { is_active: true })}

  def parent
    raise "undefined parent: Person" unless person?
    self.person
  end

  # has_many association
  def consumers
    parent.consumers.where(:broker_id => self._id)
  end

  def employers
    Employer.find_by_broker_id(self._id)
  end

  def is_active?
    self.is_active

  end

  private
    def initialize_name_full
      self.name_full = full_name
    end
end
