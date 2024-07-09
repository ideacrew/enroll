class Users::SessionsController < Devise::SessionsController
  layout 'bootstrap_4'
  include RecaptchaConcern if Settings.aca.recaptcha_enabled
  respond_to :html, :js
  after_action :log_failed_login, :only => :new
  before_action :set_ie_flash_by_announcement, only: [:new]
  before_action :enable_bs4_layout, only: [:create, :new] if EnrollRegistry.feature_enabled?(:bs4_consumer_flow)
  before_action :enable_updated_layout, only: [:create, :new]

  def new
    super do
      # Persist flash error message when signing out user
      flash.keep(:error) if flash[:error].present? && flash[:error] == l10n('devise.sessions.signed_out_concurrent_session')
    end
  end

  def create
    super do
      flash.delete(:notice) unless is_flashing_format?
      set_login_token
      location = after_sign_in_path_for(resource)
      flash[:warning] = current_user.get_announcements_by_roles_and_portal(location) if current_user.present?
    end
  end

  def destroy
    current_user.revoke_all_jwts!
    super
  end

  private

  def set_login_token
    # Set devise session token to prevent concurrent user logins.
    token = Devise.friendly_token
    session[:login_token] = token
    current_user.update_attributes!(current_login_token: token)
  end

  def log_failed_login
    return unless failed_login?
    attempted_user = User.where(email: request.filtered_parameters["user"]["login"])
    if attempted_user.present?
      SessionIdHistory.create(session_user_id: attempted_user.first.id, sign_in_outcome: "Failed", ip_address: request.remote_ip)
    end
  end

  def failed_login?
   (options = Rails.env["warden.options"]) && options[:action] == "unauthenticated"
  end

  def enable_bs4_layout
    @bs4 = true
  end

  def enable_updated_layout
    @use_bs4_layout = true
  end
end
