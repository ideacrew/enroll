class ConsumerRole
  include Mongoid::Document
  include Mongoid::Timestamps
  # include AASM

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

  field :ethnicity, type: String
  field :race, type: String
  field :birth_location, type: String
  field :marital_status, type: String

  field :citizen_status, type: String
  field :is_state_resident, type: Boolean
  field :is_incarcerated, type: Boolean
  field :is_applicant, type: Boolean
  field :is_disabled, type: Boolean

  field :is_tobacco_user, type: String, default: "unknown"
  field :language_code, type: String

  field :application_state, type: String
  field :is_active, type: Boolean, default: true

  ## Move these to Family model
  # # Writing agent credited for enrollment and transmitted on 834
  # field :writing_agent_id, type: BSON::ObjectId

  # # Agency representing this employer
  # field :broker_agency_id, type: BSON::ObjectId

  delegate :hbx_id, :hbx_id=, to: :person, allow_nil: true
  delegate :ssn, :ssn=, to: :person, allow_nil: true
  delegate :dob, :dob=, to: :person, allow_nil: true
  delegate :gender, :gender=, to: :person, allow_nil: true

  validates_presence_of :ssn, :dob, :gender, :is_incarcerated, :is_applicant, :is_state_resident, :citizen_status

  validates :citizen_status,
    inclusion: { in: ConsumerRole::CITIZEN_STATUS_KINDS, message: "%{value} is not a valid citizen status" },
    allow_blank: false


  scope :all_under_age_twenty_six, ->{ gt(:'dob' => (Date.today - 26.years))}
  scope :all_over_age_twenty_six,  ->{lte(:'dob' => (Date.today - 26.years))}

  # TODO: Add scope that accepts age range
  scope :all_over_or_equal_age, ->(age) {lte(:'dob' => (Date.today - age.years))}
  scope :all_under_or_equal_age, ->(age) {gte(:'dob' => (Date.today - age.years))}

  def parent
    raise "undefined parent: Person" unless person?
    self.person
  end

  # belongs_to writing agent (broker)
  def writing_agent=(new_writing_agent)
    raise ArgumentError.new("expected Broker class") unless new_writing_agent.is_a? Broker
    self.new_writing_agent_id = new_writing_agent._id
  end

  def writing_agent
    Broker.find(self.writing_agent_id) unless writing_agent_id.blank?
  end

  # belongs_to BrokerAgency
  def broker_agency=(new_broker_agency)
    raise ArgumentError.new("expected BrokerAgency class") unless new_broker_agency.is_a? BrokerAgency
    self.broker_agency_id = new_broker_agency._id
  end

  def broker_agency
    BrokerAgency.find(self.broker_agency_id) unless broker_agency_id.blank?
  end

  def families
    Family.by_consumerRole(self)
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


  # aasm column: "application_state" do
  #   state :enrollment_closed, initial: true
  #   state :open_enrollment_period
  #   state :special_enrollment_period
  #   state :open_and_special_enrollment_period

  #   event :open_enrollment do
  #     transitions from: :open_enrollment_period, to: :open_enrollment_period
  #     transitions from: :special_enrollment_period, to: :open_and_special_enrollment_period
  #     transitions from: :open_and_special_enrollment_period, to: :open_and_special_enrollment_period
  #     transitions from: :enrollment_closed, to: :open_enrollment_period
  #   end
  # end

  def is_active?
    self.is_active
  end

end
