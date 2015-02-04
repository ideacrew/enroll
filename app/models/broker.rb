class Broker
  include Mongoid::Document
  include Mongoid::Timestamps

  # Broker National Producer Number (unique identifier)
  field :npn, type: String
  field :agency_id, type: BSON::ObjectId

  field :aasm_state, type: String
  field :aasm_message, type: String
  field :is_active, type: Boolean, default: true

  delegate :hbx_id, :hbx_id=, to: :person, allow_nil: true

  validates_presence_of :npn, :agency_id

  # scope :all_active_brokers, ->{ and({ kind: "broker" }, { is_active: true })}
  # scope :all_active_tpzs, ->{ and({ kind: "tpa" }, { is_active: true })}

  def parent
    raise "undefined parent: Person" unless self.person?
    self.person
  end

  # belongs_to agency
  def agency=(new_agency)
    return if new_agency.blank?
    self.agency_id = new_agency._id
  end

  def agency
    return unless has_agency?
    BrokerAgency.find(self.agency_id)
  end

  def has_agency?
    !agency_id.blank?
  end

  def self.find_by_agency(agency)
    return unless broker.is_a? BrokerAgency
    where(agency_id: agency._id)
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
