class ConsumerRole
  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM

  embedded_in :person

  INTERACTIVE_IDENTITY_VERIFICATION_SUCCESS_CODE = "acc"

  VLP_AUTHORITY_KINDS = %w(ssa dhs hbx)
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

  field :vlp_verified_state, type: String, default: "identity_unverified"
  field :vlp_verified_date, type: Date
  field :vlp_authority, type: String
  field :vlp_document_id, type: String

  field :citizen_status, type: String
  field :is_state_resident, type: Boolean

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
    return @person_find if defined? @person_find
    consumer_role_id = BSON::ObjectId.from_string(consumer_role_id) if consumer_role_id.is_a? String
    @person_find = Person.where("consumer_role._id" => consumer_role_id).first.consumer_role unless consumer_role_id.blank?
  end

  def is_active?
    self.is_active
  end

  # RIDP and Verify Lawful Presence workflow.  IVL Consumer primary applicant must be in identity_verified state 
  # to proceed with application.  Each IVL Consumer enrolled for benefit coverage must (eventually) pass 

  ## TODO: Move RIDP to user model
  aasm do
    state :identity_unverified, initial: true
    state :identity_followup_pending            # Identity unconfirmed due to service failure or negative response
    state :identity_verified                    # Identity confirmed via RIDP services or subsequent followup
    state :identity_invalid

    # state :lawful_presence_unverified
    state :vlp_request_pending, :after_enter => :vlp_request_submitted
    state :lawful_presence_verified
    state :fdsh_service_error
    state :lawful_presence_followup_pending     # Federal hub non-reponsive
    state :vlp_documentation_review_pending
    state :not_lawfully_present                 # Federal Hub returned negative result

    event :verify_identity do
      transitions from: [:identity_unverified, :identity_followup_pending], to: :identity_verified, :guard => :identity_verification_succeeded?
      transitions from: :identity_unverified, to: :identity_followup_pending, :guard => :identity_verification_pending?
    end

    event :import_identity, :guard => :identity_metadata_provided? do
      transitions from: :identity_unverified, to: :identity_verified, :guard => :identity_verification_succeeded?
      transitions from: :identity_unverified, to: :identity_followup_pending, :guard => :identity_verification_pending?
    end

    event :revoke_identity do
      transitions from: [:identity_unverified, :identity_followup_pending, :identity_verified], to: :identity_invalid
    end

    event :request_vlp_service do
      transitions from: :identity_unverified, to: :vlp_request_pending
      transitions from: :identity_verified,   to: :vlp_request_pending
    end

    event :verify_lawful_presence do
      transitions from: :vlp_request_pending, to: :lawful_presence_verified, :guard => :vlp_succeeded?
      transitions from: :vlp_request_pending, to: :not_lawfully_present, :guard => :vlp_denied?
      transitions from: :vlp_request_pending, to: :fdsh_service_error
    end

    event :retry_fdsh_service do
      transitions from: :fdsh_service_error, to: :lawful_presence_verified, :guard => :vlp_succeeded?
      transitions from: :fdsh_service_error, to: :not_lawfully_present, :guard => :vlp_denied?
      transitions from: :fdsh_service_error, to: :lawful_presence_followup_pending, :guard => :retry_period_expired?
    end

    event :submit_documentation do
      transitions from: :lawful_presence_followup_pending, to: :vlp_documentation_review_pending
      transitions from: :not_lawfully_present, to: :vlp_documentation_review_pending
    end

    event :grant_vlp_status do
      transitions from: :vlp_documentation_review_pending, to: :lawful_presence_verified
    end

    event :deny_vlp_status do
      transitions from: :vlp_documentation_review_pending, to: :not_lawfully_present
    end
  end

private
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

  def vlp_succeeded?
  end

  def vlp_denied?
  end

  def retry_period_expired?
  end


end
