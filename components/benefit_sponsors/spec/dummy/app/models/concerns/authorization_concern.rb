module AuthorizationConcern
  extend ActiveSupport::Concern

  included do
    # Include default devise modules. Others available are:
    # :confirmable, :lockable, :timeoutable and :omniauthable

    ## Database authenticatable
    field :email,              type: String, default: ""
    field :encrypted_password, type: String, default: ""
    field :authentication_token

    ## Recoverable
    embeds_many :security_question_responses
    field :reset_password_token,   type: String
    field :reset_password_sent_at, type: Time
    field :identity_confirmed_token, type: String

    ## Rememberable
    field :remember_created_at, type: Time

    ## Trackable
    field :sign_in_count,      type: Integer, default: 0
    field :current_sign_in_at, type: Time
    field :last_sign_in_at,    type: Time
    field :current_sign_in_ip, type: String
    field :last_sign_in_ip,    type: String

    ## Lockable
    field :failed_attempts, type: Integer, default: 0 # Only if lock strategy is :failed_attempts
    field :unlock_token,    type: String # Only if unlock strategy is :email or :both
    field :locked_at,       type: Time

    field :password # ToDO - Fix this correctly
    field :password_confirmation # ToDO - Fix this correctly

    ## Confirmable
    # field :confirmation_token,   type: String
    # field :confirmed_at,         type: Time
    # field :confirmation_sent_at, type: Time
    # field :unconfirmed_email,    type: String # Only if using reconfirmable

    scope :locked, ->{ where(:locked_at.ne => nil) }
    scope :unlocked, ->{ where(locked_at: nil) }

    before_save :ensure_authentication_token

    def ensure_authentication_token
      if authentication_token.blank?
        self.authentication_token = generate_authentication_token
      end
      true
    end

    def generate_authentication_token
      loop do
        token = Devise.friendly_token
        break token unless User.where(authentication_token: token).first
      end
    end

    def lockable_notice
      self.locked_at.nil? ? 'unlocked' : 'locked'
    end

    def locked?
      self.locked_at.present?
    end

    def password_required?
      !persisted? || !password.nil? || !password_confirmation.nil?
    end

    def password_complexity
      if password.present? and not password.match(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^a-zA-Z\d ]).+$/)
        errors.add :password, "must include at least one lowercase letter, one uppercase letter, one digit, and one character that is not a digit or letter or space"
      elsif password.present? and password.match(/#{::Regexp.escape(oim_id)}/i)
        errors.add :password, "cannot contain username"
      elsif password.present? and password_repeated_chars_limit(password)
        errors.add :password, "cannot repeat any character more than #{MAX_SAME_CHAR_LIMIT} times"
      elsif password.present? and password.match(/(.)\1\1/)
        errors.add :password, "must not repeat consecutive characters more than once"
      elsif password.present? and !password.match(/(.*?[a-zA-Z]){4,}/)
        errors.add :password, "must have at least 4 alphabetical characters"
      end
    end

    def password_repeated_chars_limit(password)
      return true if password.chars.group_by(&:chr).map{ |k,v| v.size}.max > MAX_SAME_CHAR_LIMIT
      false
    end

    def lock!
      if locked_at.nil?
        self.lock_access!
      else
        self.unlock_access!
      end
    end
  end

  class_methods do
    MAX_SAME_CHAR_LIMIT = 4

    def configured_password_length
      default_min, default_max = EnrollRegistry[:enroll_app].setting(:default_password_length_range).item.split("..").map(&:to_i)
      return Range.new(default_min, default_max) unless EnrollRegistry.feature_enabled?(:strong_password_length)
      Devise.password_length
    end

    def find_by_authentication_token(token)
      where(authentication_token: token).first
    end

    def send_reset_password_instructions(attributes={})
      recoverable = find_or_initialize_with_errors(reset_password_keys, attributes, :not_found)
      if !recoverable.approved?
        recoverable.errors[:base] << I18n.t("devise.failure.not_approved")
      elsif recoverable.persisted?
        recoverable.send_reset_password_instructions
      end
      recoverable
    end

    def logins_before_captcha
      4
    end

  end
end
