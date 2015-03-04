class BrokerRole
  include Mongoid::Document
  include Mongoid::Timestamps

  PROVIDER_KINDS = %W[broker assister]

  embedded_in :person

  # Broker National Producer Number (unique identifier)
  field :npn, type: String
  field :broker_agency_profile_id, type: BSON::ObjectId
  field :provider_kind, type: String

  # field :aasm_state, type: String
  # field :aasm_message, type: String
  field :is_active, type: Boolean, default: true

  delegate :hbx_id, :hbx_id=, to: :person, allow_nil: true

  accepts_nested_attributes_for :person

  validates_presence_of :npn, :provider_kind
  validates :npn, uniqueness: true
  validates :provider_kind,
    allow_blank: false,
    inclusion: { in: PROVIDER_KINDS, message: "%{value} is not a valid provider kind" }


  # scope :all_active_brokers, ->{ and({ kind: "broker" }, { is_active: true })}
  # scope :all_active_tpas, ->{ and({ kind: "tpa" }, { is_active: true })}

  # def initialize(attrs = nil, options = nil)
  #   super
  #   # put code here
  # end

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
    end
    self.broker_agency_profile
  end

  def broker_agency_profile
    BrokerAgencyProfile.find(broker_agency_profile_id) if has_broker_agency_profile?
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

  def is_active?
    @is_active
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

end
