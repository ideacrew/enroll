class User
  INTERACTIVE_IDENTITY_VERIFICATION_SUCCESS_CODE = "acc"
  include Mongoid::Document
  include Mongoid::Timestamps
  include Acapi::Notifiers

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # for i18L
  field :preferred_language, type: String, default: "en"

  ## Enable Admin approval
  ## Seed: https://github.com/plataformatec/devise/wiki/How-To%3a-Require-admin-to-activate-account-before-sign_in
  field :approved, type: Boolean, default: true

  ## Database authenticatable
  field :email,              type: String, default: ""
  field :encrypted_password, type: String, default: ""

  ## Recoverable
  field :reset_password_token,   type: String
  field :reset_password_sent_at, type: Time
  field :identity_verified_date, type: Date
  field :identity_final_decision_code, type: String
  field :identity_final_decision_transaction_id, type: String
  field :identity_response_code, type: String
  field :identity_response_description_text, type: String

  ## Rememberable
  field :remember_created_at, type: Time

  ## Trackable
  field :sign_in_count,      type: Integer, default: 0
  field :current_sign_in_at, type: Time
  field :last_sign_in_at,    type: Time
  field :current_sign_in_ip, type: String
  field :last_sign_in_ip,    type: String

  field :authentication_token
  field :roles, :type => Array, :default => []

  # Oracle Identity Manager ID
  field :oim_id, type: String, default: ""

  field :last_portal_visited, type: String
  field :idp_verified, type: Boolean, default: false

  index({preferred_language: 1})
  index({approved: 1})
  index({roles: 1},  {sparse: true}) # MongoDB multikey index
  index({email: 1},  {sparse: true, unique: true})
  index({oim_id: 1}, {sparse: true, unique: true})

  before_save :strip_empty_fields

  ROLES = {
    employee: "employee",
    resident: "resident",
    consumer: "consumer",
    broker: "broker",
    system_service: "system_service",
    web_service: "web_service",
    hbx_staff: "hbx_staff",
    employer_staff: "employer_staff",
    broker_agency_staff: "broker_agency_staff",
    assister: 'assister',
    csr: 'csr',
  }

  # Enable polymorphic associations
  belongs_to :profile, polymorphic: true

  has_one :person, dependent: :destroy
  accepts_nested_attributes_for :person, :allow_destroy => true

  # after_initialize :instantiate_person

  ## Confirmable
  # field :confirmation_token,   type: String
  # field :confirmed_at,         type: Time
  # field :confirmation_sent_at, type: Time
  # field :unconfirmed_email,    type: String # Only if using reconfirmable

  ## Lockable
  # field :failed_attempts, type: Integer, default: 0 # Only if lock strategy is :failed_attempts
  # field :unlock_token,    type: String # Only if unlock strategy is :email or :both
  # field :locked_at,       type: Time

  before_save :ensure_authentication_token

  #  after_create :send_welcome_email

  delegate :primary_family, to: :person, allow_nil: true

  attr_accessor :invitation_id
  #  validate :ensure_valid_invitation, :on => :create

  def ensure_valid_invitation
    if self.invitation_id.blank?
      errors.add(:base, "There is no valid invitation for this account.")
      return
    end
    invitation = Invitation.where(id: self.invitation_id).first
    if !invitation.present?
      errors.add(:base, "There is no valid invitation for this account.")
      return
    end
    if !invitation.may_claim?
      errors.add(:base, "There is no valid invitation for this account.")
      return
    end
  end

  def person_id
    return nil unless person.present?
    person.id
  end

  def send_welcome_email
    UserMailer.welcome(self).deliver_now
    true
  end

  def set_random_password(passwd)
    self.password = passwd
    self.password_confirmation = passwd
    self.save
  end

  def has_role?(role_sym)
    roles.any? { |r| r == role_sym.to_s }
  end

  def has_employee_role?
    has_role?(:employee)
  end

  def has_consumer_role?
    has_role?(:consumer)
  end

  def has_employer_staff_role?
    has_role?(:employer_staff)
  end

  def has_broker_agency_staff_role?
    has_role?(:broker_agency_staff)
  end

  def has_insured_role?
    has_employee_role? || has_consumer_role?
  end

  def has_broker_role?
    has_role?(:broker)
  end

  def has_hbx_staff_role?
    has_role?(:hbx_staff)
  end

  def has_csr_role?
    has_role?(:csr)
  end
  def has_assister_role?
    has_role(:assister)
  end
  def ensure_authentication_token
    if authentication_token.blank?
      self.authentication_token = generate_authentication_token
    end
    true
  end

  def instantiate_person
    self.person = Person.new
  end

  def self.send_reset_password_instructions(attributes={})
    recoverable = find_or_initialize_with_errors(reset_password_keys, attributes, :not_found)
    if !recoverable.approved?
      recoverable.errors[:base] << I18n.t("devise.failure.not_approved")
    elsif recoverable.persisted?
      recoverable.send_reset_password_instructions
    end
    recoverable
  end

  def self.find_by_authentication_token(token)
    where(authentication_token: token).first
  end

  class << self
    def current_user=(user)
      Thread.current[:current_user] = user
    end

    def current_user
      Thread.current[:current_user]
    end
  end

  # def password_digest(plaintext_password)
  #     Rypt::Sha512.encrypt(plaintext_password)
  # end
  # # Verifies whether a password (ie from sign in) is the user password.
  # def valid_password?(plaintext_password)
  #   Rypt::Sha512.compare(self.encrypted_password, plaintext_password)
  # end
  def identity_verified?
    return false if identity_final_decision_code.blank?
    identity_final_decision_code.to_s.downcase == INTERACTIVE_IDENTITY_VERIFICATION_SUCCESS_CODE
  end

  def self.get_saml_settings
     settings = OneLogin::RubySaml::Settings.new

    # When disabled, saml validation errors will raise an exception.
    settings.soft = true

    # SP section
    settings.assertion_consumer_service_url = "https://enroll-test.dchbx.org/saml/login"
    settings.assertion_consumer_logout_service_url = "https://enroll-test.dchbx.org/saml/logout"
    settings.issuer                         = "https://enroll-test.dchbx.org/saml"

    # IdP section
    settings.idp_entity_id                  = "LocalIDP"
    settings.idp_sso_target_url             = "https://DHSDCASOHSSVRQA201.dhs.dc.gov:4443/fed/idp/samlv20"
    settings.idp_slo_target_url             = "https://DHSDCASOHSSVRQA201.dhs.dc.gov:4443/fed/idp/samlv20"
    settings.idp_cert                       = "-----BEGIN CERTIFICATE-----
MIIDhzCCAm+gAwIBAgIEY6x59jANBgkqhkiG9w0BAQsFADB0MQswCQYDVQQGEwJV
UzELMAkGA1UECBMCREMxEzARBgNVBAcTCldBU0hJTkdUT0IxDTALBgNVBAoTBERD
QVMxDDAKBgNVBAsTA0RIUzEmMCQGA1UEAxMdREhTRENBU09JRFNWUlVBVDAxLmRo
cy5kYy5nb3YwHhcNMTQwMTEwMTg1NjQ3WhcNMjQwMTA4MTg1NjQ3WjB0MQswCQYD
VQQGEwJVUzELMAkGA1UECBMCREMxEzARBgNVBAcTCldBU0hJTkdUT0IxDTALBgNV
BAoTBERDQVMxDDAKBgNVBAsTA0RIUzEmMCQGA1UEAxMdREhTRENBU09JRFNWUlVB
VDAxLmRocy5kYy5nb3YwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCQ
iiDHH9JAnCqowuDTyiecnhtgLo7rMiQQQimuS0h7p1HfLOTvNgxu+2JeQu/jmXfg
pPrlmHPCMTuiT/m+5VhwYB81IuF2ZmHdvcRW+saAEyfDO0BLgsNdM66QTCXvPJOI
Kic8vMy+1bX5OS0cqrUTPA9q6uxLH/vp2onP52fJwFuDC4lh+xCa4JajwkwyvbEv
0dPH3GBJXgUmtVuamx5apMXzoxMcPUeEZtyjfgYZk1NOjckCOLMw032FEOlPextD
QAk46bA734ipsMcopTxAGla7EqIW5PYZh5Ju2pYIFKAjoXQNwD5kQ7bEhW2V3uuO
qwxszUjymIbifzVRTqCfAgMBAAGjITAfMB0GA1UdDgQWBBRS2mDuOE+PWEqp/NRM
9xw3ZyFMjTANBgkqhkiG9w0BAQsFAAOCAQEADsoCyfzE3E7r0k9f+dKBRKE3QHrn
taJw9g2TMrpoMD+5i8qU6yrXqsYwzscy0y9Cx6xRTC0JDwrIYSlJqyZIbyMG9wdd
9FC3iy4fXAgbDDRg2t8v9N/c/sKfbKaP9uVjQwfEEgGRD8u8qSIhcegtpVNyKhVH
IRm3GhAsDTm2bHkYhFGEBwa1HJINl3FLutqhROjeyjJHogFM6FFYXWUqf69NkwMz
tr5ZuSA1NBPFeZkMhqB1KKmXD3877sfrvH291wBTwTleINhhFV6/CN5CB0T/cY08
tklYiyapP34LsnWdivUWCtkiXNPHGEGq0GqAkoEnegRTrC3isqMNiATyEw==
-----END CERTIFICATE-----"
    # or settings.idp_cert_fingerprint           = "3B:05:BE:0A:EC:84:CC:D4:75:97:B3:A2:22:AC:56:21:44:EF:59:E6"
    #    settings.idp_cert_fingerprint_algorithm = XMLSecurity::Document::SHA1

    settings.name_identifier_format         = "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"

    # Security section
    settings.security[:authn_requests_signed] = false
    settings.security[:logout_requests_signed] = false
    settings.security[:logout_responses_signed] = false
    settings.security[:metadata_signed] = false
    settings.security[:digest_method] = XMLSecurity::Document::SHA1
    settings.security[:signature_method] = XMLSecurity::Document::RSA_SHA1

    settings
  end

  private
  # Remove indexed, unique, empty attributes from document
  def strip_empty_fields
    unset("email") if email.blank?
    unset("oim_id") if oim_id.blank?
  end

  def generate_authentication_token
    loop do
      token = Devise.friendly_token
      break token unless User.where(authentication_token: token).first
    end
  end
end
