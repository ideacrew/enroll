class User
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
    broker_agency_staff: "broker_agency_staff"
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

  def has_employer_staff_role?
    has_role?(:employer_staff)
  end

  def has_broker_agency_staff_role?
    has_role?(:broker_agency_staff)
  end

  def has_broker_role?
    has_role?(:broker)
  end

  def has_hbx_staff_role?
    has_role?(:hbx_staff)
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
