class ApplicationController < ActionController::Base
  # before_filter :require_login, unless: :devise_controller?

  before_filter :require_login, unless: :authentication_not_required?


  # force_ssl

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  ## Devise filters
  before_filter :authenticate_user_from_token!
  before_filter :authenticate_me!
  
  # for i18L
  before_action :set_locale

  # for current_user
  before_action :set_current_user

  # before_action do
  #   resource = controller_name.singularize.to_sym
  #   method = "#{resource}_params"
  #   params[resource] &&= send(method) if respond_to?(method, true)
  # end

  #cancancan access denied
  rescue_from CanCan::AccessDenied, with: :access_denied

  def authenticate_me!
    # Skip auth if you are trying to log in
    return true if ["welcome", "broker_roles", "office_locations", "invitations"].include?(controller_name.downcase)
    authenticate_user!
  end

  def access_denied
    render file: 'public/403.html', status: 403
  end

  private


  def secure_message(from_provider, to_provider, subject, body)
    message_params = {
      sender_id: from_provider.id,
      parent_message_id: to_provider.id,
      from: from_provider.legal_name,
      to: to_provider.legal_name,
      subject: subject,
      body: body
    }

    create_secure_message(message_params, to_provider, :inbox)
    create_secure_message(message_params, from_provider, :sent)
  end

  def create_secure_message(message_params, inbox_provider, folder)
    message = Message.new(message_params)
    message.folder =  Message::FOLDER_TYPES[folder]
    msg_box = inbox_provider.inbox 
    msg_box.post_message(message)
    msg_box.save
  end

  def set_locale
    requested_locale = params[:locale] || user_preferred_language || extract_locale_from_accept_language_header || I18n.default_locale
    requested_locale = I18n.default_locale unless I18n.available_locales.include? requested_locale.try(:to_sym)
    I18n.locale = requested_locale
  end 

  def extract_locale_from_accept_language_header
    if request.env['HTTP_ACCEPT_LANGUAGE']
      request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first
    else
      nil
    end
  end

  def user_preferred_language
    current_user.try(:preferred_language)
  end

  protected

  # Broker Signup form should be accessibile for anonymous users
  def authentication_not_required?
    devise_controller? || (controller_name == "broker_roles") || (controller_name == "office_locations") || (controller_name == "invitations")
  end

  def require_login
    unless current_user
      session[:portal] = url_for(params)
      redirect_to new_user_session_url
    end
  end

  def after_sign_in_path_for(resource)
    session[:portal] || request.referer || root_path
  end

  def authenticate_user_from_token!
    user_token = params[:user_token].presence
    user = user_token && User.find_by_authentication_token(user_token.to_s)
    if user
      sign_in user, store: false
    end
  end

  def cur_page_no(alph="a")
    page_string = params.permit(:page)[:page]
    page_string.blank? ? alph : page_string.to_s
  end

  def page_alphabets(source, field)
    if fields = field.split(".") and fields.count > 1
      word_arr = source.map do |s|
        fields.each do |f|
          s = s.send(f)
        end
        s
      end
      word_arr.uniq.collect {|word| word.first.upcase}.uniq.sort
    else
      source.distinct(field).collect {|word| word.first.upcase}.uniq.sort
    end
  rescue
    ("A".."Z").to_a
  end

  def set_current_user
    User.current_user = current_user
  end

  def set_current_person
    if current_user.person.try(:broker_role).try(:broker_agency_profile_id)
      @person = Person.find(session[:person_id])
    else
      @person = current_user.person
    end
  end
end
