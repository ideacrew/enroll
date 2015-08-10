class ConsumerRole
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :person

  field :birth_location, type: String
  field :marital_status, type: String
  field :is_active, type: Boolean, default: true
  field :is_applicant, type: Boolean

  delegate :hbx_id, :hbx_id=, to: :person, allow_nil: true
  delegate :ssn,    :ssn=,    to: :person, allow_nil: true
  delegate :dob,    :dob=,    to: :person, allow_nil: true
  delegate :gender, :gender=, to: :person, allow_nil: true

  delegate :vlp_authority,      :vlp_authority=,     to: :person, allow_nil: true
  delegate :vlp_document_id,    :vlp_document_id=,   to: :person, allow_nil: true
  delegate :vlp_evidences,      :vlp_evidences=,     to: :person, allow_nil: true

  delegate :citizen_status,     :citizen_status=,    to: :person, allow_nil: true
  delegate :is_state_resident,  :is_state_resident=, to: :person, allow_nil: true
  delegate :is_incarcerated,    :is_incarcerated=,   to: :person, allow_nil: true

  delegate :identity_verified_state,      :identity_verified_state=,      to: :person, allow_nil: false
  delegate :identity_verified_date,       :identity_verified_date=,       to: :person, allow_nil: true
  delegate :identity_verified_evidences,  :identity_verified_evidences=,  to: :person, allow_nil: true
  delegate :identity_final_decision_code, :identity_final_decision_code=, to: :person, allow_nil: true
  delegate :identity_response_code,       :identity_response_code=,       to: :person, allow_nil: true
  delegate :verify_identity, to: :person
  delegate :import_identity, to: :person

  delegate :race,               :race=,              to: :person, allow_nil: true
  delegate :ethnicity,          :ethnicity=,         to: :person, allow_nil: true
  delegate :is_disabled,        :is_disabled=,       to: :person, allow_nil: true

  validates_presence_of :ssn, :dob, :gender, :identity_verified_state

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
    @person_find = Person.where("consumer_role._id" => consumer_role_id).first.consumer_role unless consumer_role_id.blank?
  end

  def is_active?
    self.is_active
  end

end
