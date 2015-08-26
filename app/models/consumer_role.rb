class ConsumerRole
  RESIDENCY_VERIFICATION_REQUEST_EVENT_NAME = "local.enroll.residency.verification_request"

  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM
  include Acapi::Notifiers

  embedded_in :person

  INTERACTIVE_IDENTITY_VERIFICATION_SUCCESS_CODE = "acc"

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

  ## Verified Lawful Presence (VLP)

  # Alien number (A Number):  9 character string
  # CitizenshipNumber:        7-12 character string
  # I-94:                     11 character string
  # NaturalizationNumber:     7-12 character string
  # PassportNumber:           6-12 character string
  # ReceiptNumber:            13 character string, first 3 alpha, remaining 10 string
  # SevisID:                  11 digit string, first char is "N"
  # VisaNumber:               8 character string

  VLP_DOCUMENT_IDENTIFICATION_KINDS = [
      "A Number",
      "I-94 Number",
      "SEVIS ID",
      "Visa Number",
      "Passport Number",
      "Receipt Number",
      "Naturalization Number",
      "Citizenship Number"
    ]

  VLP_DOCUMENT_KINDS = [
      "I-327 (Reentry Permit)",
      "I-551 (Permanent Resident Card)",
      "I-571 (Refugee Travel Document)",
      "I-766 (Employment Authorization Card)",
      "Certificate of Citizenship",
      "Naturalization Certificate",
      "Machine Readable Immigrant Visa (with Temporary I-551 Language)",
      "Temporary I-551 Stamp (on passport or I-94)",
      "I-94 (Arrival/Departure Record)",
      "I-94 (Arrival/Departure Record) in Unexpired Foreign Passport",
      "Unexpired Foreign Passport",
      "I-20 (Certificate of Eligibility for Nonimmigrant (F-1) Student Status)",
      "DS2019 (Certificate of Eligibility for Exchange Visitor (J-1) Status)"
    ]

  # FiveYearBarApplicabilityIndicator ??

  field :aasm_state, type: String, default: "identity_unverified"
  field :identity_verified_date, type: Date
  field :identity_final_decision_code, type: String
  field :identity_final_decision_transaction_id, type: String
  field :identity_response_code, type: String
  field :identity_response_description_text, type: String

  delegate :citizen_status,:vlp_verified_date, :vlp_authority, :vlp_document_id, to: :lawful_presence_determination_instance
  delegate :citizen_status=,:vlp_verified_date=, :vlp_authority=, :vlp_document_id=, to: :lawful_presence_determination_instance

  field :is_state_resident, type: Boolean
  field :residency_determined_at, type: DateTime

  field :is_applicant, type: Boolean  # Consumer is applying for benefits coverage
  field :birth_location, type: String
  field :marital_status, type: String
  field :is_active, type: Boolean, default: true

  delegate :hbx_id, :hbx_id=, to: :person, allow_nil: true
  delegate :ssn,    :ssn=,    to: :person, allow_nil: true
  delegate :dob,    :dob=,    to: :person, allow_nil: true
  delegate :gender, :gender=, to: :person, allow_nil: true

  delegate :is_incarcerated,    :is_incarcerated=,   to: :person, allow_nil: true

  delegate :race,               :race=,              to: :person, allow_nil: true
  delegate :ethnicity,          :ethnicity=,         to: :person, allow_nil: true
  delegate :is_disabled,        :is_disabled=,       to: :person, allow_nil: true

  embeds_many :documents, as: :documentable
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
    ["Certificate of Citizenship", "Naturalization Certificate"]
  end

  # RIDP and Verify Lawful Presence workflow.  IVL Consumer primary applicant must be in identity_verified state
  # to proceed with application.  Each IVL Consumer enrolled for benefit coverage must (eventually) pass

  ## TODO: Move RIDP to user model
  aasm do
    state :identity_unverified, initial: true
    state :identity_followup_pending            # Identity unconfirmed due to service failure or negative response
    state :identity_verified                    # Identity confirmed via RIDP services or subsequent followup
    state :identity_invalid

    state :verifications_pending
    state :verifications_outstanding
    state :fully_verified

    event :verify_identity, :after => :record_transition  do
      transitions from: [:identity_unverified, :identity_followup_pending], to: :identity_verified, :guard => :identity_verification_succeeded?
      transitions from: :identity_unverified, to: :identity_followup_pending, :guard => :identity_verification_pending?
    end

    event :import_identity, :guard => :identity_metadata_provided?, :after => :record_transition  do
      transitions from: :identity_unverified, to: :identity_verified, :guard => :identity_verification_succeeded?
      transitions from: :identity_unverified, to: :identity_followup_pending, :guard => :identity_verification_pending?
    end

    event :revoke_identity, :after => :record_transition  do
      transitions from: [:identity_unverified, :identity_followup_pending, :identity_verified], to: :identity_invalid
    end

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

  def identity_verification_succeeded?
    identity_final_decision_code.to_s.downcase == INTERACTIVE_IDENTITY_VERIFICATION_SUCCESS_CODE
  end

  def identity_verification_denied?
    identity_final_decision_code.to_s.downcase == INTERACTIVE_IDENTITY_VERIFICATION_SUCCESS_CODE
  end

  def identity_verification_pending?
    identity_final_decision_code.to_s.downcase == "ref" && identity_response_code.present?
  end

  def identity_metadata_provided?
    identity_final_decision_code.present? && identity_response_code.present?
  end

end
