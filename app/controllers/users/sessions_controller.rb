class Users::SessionsController < Devise::SessionsController
  layout 'bootstrap_4'
  include RecaptchaConcern if Settings.aca.recaptcha_enabled
  respond_to :html, :js
  after_action :log_failed_login, :only => :new
  before_action :set_ie_flash_by_announcement, only: [:new]
  skip_before_action :check_concurrent_sessions

  def new
    super do
      # Persist flash error message when signing out user
      flash.keep(:error) if flash[:error].present? && flash[:error] == l10n('devise.sessions.signed_out_concurrent_session')
    end
  end

  def create
    self.resource = warden.authenticate!(auth_options)
    set_flash_message(:notice, :signed_in) if is_flashing_format?
    sign_in(resource_name, resource)
    set_login_token
    yield resource if block_given?
    location = after_sign_in_path_for(resource)
    flash[:warning] = current_user.get_announcements_by_roles_and_portal(location) if current_user.present?
    respond_with resource, location: location
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
end
