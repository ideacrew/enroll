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

  ROLES = {
    employer: "Employer",
    employee: "Employee",
    broker: "Broker",
    undocumented_consumer: "Undocumented Consumer",
    qhp_consumer: "QHP Consumer",
    hbx_employee: "HBX Employee",
    system_service: "System Service",
    web_service: "Web Service"
  }

  PROFILES = {
    employer_profile: "employer_profile",
    broker_profile: "broker_profile",
    employee_profile: "employee_profile"
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

  after_create :send_welcome_email

  def send_welcome_email
    UserMailer.welcome(self).deliver_now
    true
  end

  def has_role?(role_sym)
    roles.any? { |r| r == role_sym }
  end

  def ensure_authentication_token
    if authentication_token.blank?
      self.authentication_token = generate_authentication_token
    end
    true
  end

  def active_for_authentication?
    super && approved?
  end

  def instantiate_person
    self.build_person if self.person.nil?
  end

  def inactive_message
    if !approved?
      :not_approved
    else
      super # Use whatever other message
    end
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

  def self.find_all_by_approved(appvd_status)
    where(approved: appvd_status)
  end

  def self.find_by_authentication_token(token)
    where(authentication_token: token).first
  end

protected
  def send_admin_mail
    AdminMailer.new_user_waiting_for_approval(self).deliver
  end

private
  def generate_authentication_token
    loop do
      token = Devise.friendly_token
      break token unless User.where(authentication_token: token).first
    end
  end
end
