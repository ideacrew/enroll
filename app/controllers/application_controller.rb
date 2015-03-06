class ApplicationController < ActionController::Base
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

  # After successful login, redirect to this page
  def after_sign_in_path_for(resource)
    url, profile = root_path, User::PROFILES
    session[:user_role] = if request.referer.include?("employers")
      profile[:employer_profile]
    elsif request.referer.include?("brokers")
      profile[:broker_profile]
    else
      profile[:employee_profile]
    end
    resource.update_attribute(:role, resource.role.push(session[:user_role])) if !resource.role.include?(session[:user_role])
    if session[:user_role] == profile[:employer_profile]
      url = current_user.person.present? ? employers_root_path : new_employers_employer_path
    end
    if session[:user_role] == profile[:broker_profile]
      url = current_user.person.present? ? brokers_path : new_brokers_broker_path
    end
    if session[:user_role] == profile[:employee_profile]
      url = current_user.person.present? ? person_path : new_person_path
    end
    url
  end

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
