class Consumer
  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM


  embedded_in :person

  CITIZEN_STATUS_KINDS = %W[
      us_citizen
      naturalized_citizen
      alien_lawfully_present
      lawful_permanent_resident
      indian_tribe_member
      undocumented_immigrant
      not_lawfully_present_in_us
  ]

  field :ethnicity, type: String, default: ""
  field :race, type: String, default: ""
  field :birth_location, type: String, default: ""
  field :marital_status, type: String, default: ""

  field :citizen_status, type: String
  field :is_state_resident, type: Boolean, default: true
  field :is_incarcerated, type: Boolean, default: false
  field :is_applicant, type: Boolean, default: true
  field :is_disabled, type: Boolean, default: false

  field :is_tobacco_user, type: String, default: "unknown"
  field :language_code, type: String

  field :application_state, type: String
  field :is_active, type: Boolean, default: true

  # Writing agent credited for enrollment and transmitted on 834
  field :broker_id, type: BSON::ObjectId

  # Agency representing this employer
  field :broker_agency_id, type: BSON::ObjectId

  delegate :hbx_id, :hbx_id=, to: :person, allow_nil: true
  delegate :ssn, :ssn=, to: :person, allow_nil: true
  delegate :dob, :dob=, to: :person, allow_nil: true
  delegate :gender, :gender=, to: :person, allow_nil: true

  validates_presence_of :person, :ssn, :dob, :gender, :is_incarcerated, :is_applicant,
    :is_state_resident, :citizen_status

  validates :citizen_status,
    inclusion: { in: CITIZEN_STATUS_KINDS, message: "%{value} is not a valid citizen status" },
    allow_blank: false

  validates :ssn,
    length: { minimum: 9, maximum: 9, message: "Consumer SSN must be 9 digits" },
    numericality: true,
    uniqueness: true

  scope :all_under_age_twenty_six, ->{ gt(:'dob' => (Date.today - 26.years))}
  scope :all_over_age_twenty_six,  ->{lte(:'dob' => (Date.today - 26.years))}

  # TODO: Add scope that accepts age range
  scope :all_over_or_equal_age, ->(age) {lte(:'dob' => (Date.today - age.years))}
  scope :all_under_or_equal_age, ->(age) {gte(:'dob' => (Date.today - age.years))}

  def parent
    raise "undefined parent: Person" unless person?
    self.person
  end

  # belongs_to Broker
  def broker=(new_broker)
    return unless new_broker.is_a? Broker
    self.broker_id = new_broker._id
  end

  def broker
    parent.broker.find(self.broker_id) unless broker_id.blank?
  end

  # belongs_to BrokerAgency
  def broker_agency=(new_broker_agency)
    return unless new_broker_agency.is_a? BrokerAgency
    self.broker_agency_id = new_broker_agency._id
  end

  def broker_agency
    BrokerAgency.find(self.broker_agency_id) unless broker_agency_id.blank?
  end

  def families
    Family.by_consumer(self)
  end

  def phone
    parent.phones.detect { |phone| phone.kind == "home" }
  end

  def email
    parent.emails.detect { |email| email.kind == "home" }
  end

  def home_address
    addresses.detect { |adr| adr.kind == "home" }
  end

  def mailing_address
    addresses.detect { |adr| adr.kind == "mailing" } || home_address
  end

  def billing_address
    addresses.detect { |adr| adr.kind == "billing" } || home_address
  end


  aasm column: "application_state" do
    state :enrollment_closed, initial: true
    state :open_enrollment_period
    state :special_enrollment_period
    state :open_and_special_enrollment_period

    event :open_enrollment do
      transitions from: :open_enrollment_period, to: :open_enrollment_period
      transitions from: :special_enrollment_period, to: :open_and_special_enrollment_period
      transitions from: :open_and_special_enrollment_period, to: :open_and_special_enrollment_period
      transitions from: :enrollment_closed, to: :open_enrollment_period
    end
  end

  def is_active?
    self.is_active
  end

end
