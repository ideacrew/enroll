class ConsumerRole
  RESIDENCY_VERIFICATION_REQUEST_EVENT_NAME = "local.enroll.residency.verification_request"

  include Mongoid::Document
  include Mongoid::Timestamps
  include Acapi::Notifiers
  include AASM

  embedded_in :person

  VLP_AUTHORITY_KINDS = %w(ssa dhs hbx)
  NATURALIZED_CITIZEN_STATUS = "naturalized_citizen"
  INDIAN_TRIBE_MEMBER_STATUS = "indian_tribe_member"
  US_CITIZEN_STATUS = "us_citizen"
  NOT_LAWFULLY_PRESENT_STATUS = "not_lawfully_present_in_us"
  ALIEN_LAWFULLY_PRESENT_STATUS = "alien_lawfully_present"

  US_CITIZEN_STATUS_KINDS = %W(
  us_citizen
  naturalized_citizen
  indian_tribe_member
  )
  CITIZEN_STATUS_KINDS = %w(
      us_citizen
      naturalized_citizen
      alien_lawfully_present
      lawful_permanent_resident
      indian_tribe_member
      undocumented_immigrant
      not_lawfully_present_in_us
  )

  ACA_ELIGIBLE_CITIZEN_STATUS_KINDS = %W(
      us_citizen
      naturalized_citizen
      indian_tribe_member
  )

  # FiveYearBarApplicabilityIndicator ??
  field :five_year_bar, type: Boolean, default: false
  field :requested_coverage_start_date, type: Date, default: Date.today
  field :aasm_state, type: String, default: "verifications_pending"

  delegate :citizen_status,:vlp_verified_date, :vlp_authority, :vlp_document_id, to: :lawful_presence_determination_instance
  delegate :citizen_status=,:vlp_verified_date=, :vlp_authority=, :vlp_document_id=, to: :lawful_presence_determination_instance

  field :is_state_resident, type: Boolean
  field :residency_determined_at, type: DateTime

  field :is_applicant, type: Boolean  # Consumer is applying for benefits coverage
  field :birth_location, type: String
  field :marital_status, type: String
  field :is_active, type: Boolean, default: true

    field :raw_event_responses, type: Array, default: [] #e.g. [{:lawful_presence_response => payload}]

  delegate :hbx_id, :hbx_id=, to: :person, allow_nil: true
  delegate :ssn,    :ssn=,    to: :person, allow_nil: true
  delegate :dob,    :dob=,    to: :person, allow_nil: true
  delegate :gender, :gender=, to: :person, allow_nil: true

  delegate :is_incarcerated,    :is_incarcerated=,   to: :person, allow_nil: true

  delegate :race,               :race=,              to: :person, allow_nil: true
  delegate :ethnicity,          :ethnicity=,         to: :person, allow_nil: true
  delegate :is_disabled,        :is_disabled=,       to: :person, allow_nil: true

  embeds_many :documents, as: :documentable
  embeds_many :vlp_documents, as: :documentable
  embeds_many :workflow_state_transitions, as: :transitional

  accepts_nested_attributes_for :person, :workflow_state_transitions

  validates_presence_of :ssn, :dob, :gender, :is_applicant

  validates :vlp_authority,
    allow_blank: true,
    inclusion: { in: VLP_AUTHORITY_KINDS, message: "%{value} is not a valid identity authority" }

  validates :citizen_status,
    allow_blank: true,
    inclusion: { in: CITIZEN_STATUS_KINDS, message: "%{value} is not a valid citizen status" }

  scope :all_under_age_twenty_six, ->{ gt(:'dob' => (Date.today - 26.years))}
  scope :all_over_age_twenty_six,  ->{lte(:'dob' => (Date.today - 26.years))}

  # TODO: Add scope that accepts age range
  scope :all_over_or_equal_age, ->(age) {lte(:'dob' => (Date.today - age.years))}
  scope :all_under_or_equal_age, ->(age) {gte(:'dob' => (Date.today - age.years))}

  alias_method :is_state_resident?, :is_state_resident
  alias_method :is_incarcerated?,   :is_incarcerated

  embeds_one :lawful_presence_determination

  embeds_many :local_residency_responses, class_name:"EventResponse"

  after_initialize :setup_lawful_determination_instance

  def start_residency_verification_process
    notify(RESIDENCY_VERIFICATION_REQUEST_EVENT_NAME, {:person => self.person})
  end

  def setup_lawful_determination_instance
    unless self.lawful_presence_determination.present?
      self.lawful_presence_determination = LawfulPresenceDetermination.new
    end
  end

  def lawful_presence_determination_instance
    setup_lawful_determination_instance
    self.lawful_presence_determination
  end

  def is_aca_enrollment_eligible?
    is_hbx_enrollment_eligible? &&
    Person::ACA_ELIGIBLE_CITIZEN_STATUS_KINDS.include?(citizen_status)
  end

  def is_hbx_enrollment_eligible?
    is_state_resident? && !is_incarcerated?
  end

  def parent
    raise "undefined parent: Person" unless person?
    self.person
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

  def self.find(consumer_role_id)
    consumer_role_id = BSON::ObjectId.from_string(consumer_role_id) if consumer_role_id.is_a? String
    @person_find = Person.where("consumer_role._id" => consumer_role_id).first.consumer_role unless consumer_role_id.blank?
  end

  def is_active?
    self.is_active
  end

  def self.naturalization_document_types
    VlpDocument::NATURALIZATION_DOCUMENT_TYPES
  end

  # RIDP and Verify Lawful Presence workflow.  IVL Consumer primary applicant must be in identity_verified state
  # to proceed with application.  Each IVL Consumer enrolled for benefit coverage must (eventually) pass

  ## TODO: Move RIDP to user model
  aasm do
    state :verifications_pending, initial: true
    state :verifications_outstanding
    state :fully_verified

    event :deny_lawful_presence, :after => [:record_transition, :mark_lp_denied] do
      transitions from: :verifications_pending, to: :verifications_pending, guard: :residency_pending?
      transitions from: :verifications_pending, to: :verifications_outstanding
      transitions from: :verifications_outstanding, to: :verifications_outstanding
    end

    event :authorize_lawful_presence, :after => [:record_transition, :mark_lp_authorized] do
      transitions from: :verifications_pending, to: :verifications_pending, guard: :residency_pending?
      transitions from: :verifications_pending, to: :fully_verified, guard: :residency_verified?
      transitions from: :verifications_outstanding, to: :verifications_outstanding, guard: :residency_denied?
      transitions from: :verifications_outstanding, to: :fully_verified, guard: :residency_verified?
    end

    event :authorize_residency, :after => [:record_transition, :mark_residency_authorized] do
      transitions from: :verifications_pending, to: :verifications_pending, guard: :lawful_presence_pending?
      transitions from: :verifications_pending, to: :fully_verified, guard: :lawful_presence_verified?
      transitions from: :verifications_outstanding, to: :verifications_outstanding, guard: :lawful_presence_outstanding?
      transitions from: :verifications_outstanding, to: :fully_verified, guard: :lawful_presence_authorized?
    end

    event :deny_residency, :after => [:record_transition, :mark_residency_denied] do
      transitions from: :verifications_pending, to: :verifications_pending, guard: :lawful_presence_pending?
      transitions from: :verifications_pending, to: :verifications_outstanding
      transitions from: :verifications_outstanding, to: :verifications_outstanding, guard: :lawful_presence_outstanding?
      transitions from: :verifications_outstanding, to: :fully_verified, guard: :lawful_presence_authorized?
    end
  end

private
  def mark_residency_denied(*args)
    self.residency_determined_at = Time.now
    self.is_state_resident = false
  end

  def mark_residency_authorized(*args)
    self.residency_determined_at = Time.now
    self.is_state_resident = true
  end

  def lawful_presence_pending?
    lawful_presence_determination.verification_pending?
  end

  def lawful_presence_outstanding?
    lawful_presence_determination.verification_outstanding?
  end

  def lawful_presence_authorized?
    lawful_presence_determination.verification_successful?
  end

  def residency_pending?
    is_state_resident.nil?
  end

  def residency_denied?
    (!is_state_resident.nil?) && (!is_state_resident)
  end

  def residency_verified?
    is_state_resident?
  end

  def mark_lp_authorized(*args)
    if aasm.current_event == :authorize_lawful_presence!
      lawful_presence_determination.authorize!(*args)
    else
      lawful_presence_determination.authorize(*args)
    end
  end

  def mark_lp_denied(*args)
    if aasm.current_event == :deny_lawful_presence!
      lawful_presence_determination.deny!(*args)
    else
      lawful_presence_determination.deny(*args)
    end
  end

  def record_transition(*args)
    workflow_state_transitions << WorkflowStateTransition.new(
      from_state: aasm.from_state,
      to_state: aasm.to_state
    )
  end

end
