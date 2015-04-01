class ApplicationController < ActionController::Base

  # force_ssl
  
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  ## Devise filters
  before_filter :authenticate_user_from_token!
  before_filter :authenticate_me!

  # before_action do
  #   resource = controller_name.singularize.to_sym
  #   method = "#{resource}_params"
  #   params[resource] &&= send(method) if respond_to?(method, true)
  # end

  #cancancan access denied
  rescue_from CanCan::AccessDenied, with: :access_denied

  def authenticate_me!
    # Skip auth if you are trying to log in
    return true if controller_name.downcase == "welcome"
    authenticate_user!
  end

  def access_denied
    render file: 'public/403.html', status: 403
  end

  private

  def authenticate_user_from_token!
    user_token = params[:user_token].presence
    user = user_token && User.find_by_authentication_token(user_token.to_s)
    if user
      sign_in user, store: false
    end
  end

end
