# frozen_string_literal: true

# controller for user account creation
class Users::RegistrationsController < Devise::RegistrationsController
  include RecaptchaConcern
  layout 'bootstrap_4'

  before_action :enable_bs4_layout, only: [:create, :new] if EnrollRegistry.feature_enabled?(:bs4_consumer_flow)
  before_action :enable_updated_layout, only: [:create, :new]
  before_action :configure_sign_up_params, only: [:create]

  # used with respond_with in the create action
  respond_to :html
  # before_action :configure_account_update_params, only: [:update]

  # GET /resource/sign_up
  # def new
  #   super
  # end

  # POST /resource
  def create
    build_resource(sign_up_params)

#   Check for curam user email, if present then restrict the user.
    if CuramUser.match_unique_login(resource.oim_id).first.present?
      flash[:alert] = "An account with this username ( #{params[:user][:oim_id]} ) already exists. #{view_context.link_to('Click here', SamlInformation.account_recovery_url)} if you've forgotten your password."
      respond_to do |format|
        format.html { render :new }
      end
      return
    end

    if resource.email.strip.present? && CuramUser.match_unique_login(resource.email.strip).first.present?
      flash[:alert] = "An account with this email ( #{params[:user][:email]} ) already exists. #{view_context.link_to('Click here', SamlInformation.account_recovery_url)} if you've forgotten your password."
      respond_to do |format|
        format.html { render :new }
      end
      return
    end

    headless = User.where(email: /^#{Regexp.quote(resource.email)}$/i).first
    headless.destroy if headless.present? && !headless.person.present?

    resource.email = resource.oim_id if resource.email.blank? && resource.oim_id =~ Devise.email_regexp
    resource.handle_headless_records
    resource_saved = verify_recaptcha_if_needed && resource.save
    yield resource if block_given?
    if resource_saved
      # FIXME: DON'T EVER DO THIS!
      # HACK: DON'T EVER DO THIS!
      # NONONONOBAD: We are only doing this because the enterprise service
      #              can't accept a password with a standard hash.
      session["stashed_password"] = sign_up_params["password"]
      if resource.active_for_authentication?
        set_sign_up_warning
        sign_up(resource_name, resource)
        location = after_sign_in_path_for(resource)
        flash[:warning] = current_user.get_announcements_by_roles_and_portal(location) if current_user.present?
        respond_with resource, location: location
      else
        set_flash_message :notice, :"signed_up_but_#{resource.inactive_message}" if is_flashing_format?
        expire_data_after_sign_in!
        respond_with resource, location: after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords resource
      @validatable = devise_mapping.validatable?
      @minimum_password_length = resource_class.password_length.min if @validatable
      respond_to do |format|
        format.html { render :new }
      end
    end
  end

  def verify_recaptcha_if_needed
    return true unless helpers.registration_recaptcha_enabled?("user_account")
    verify_recaptcha(model: resource)
  end

  # GET /resource/edit
  # def edit
  #   super
  # end

  # PUT /resource
  # def update
  #   super
  # end

  # DELETE /resource
  # def destroy
  #   super
  # end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  protected

  # You can put the params you want to permit in the empty array.
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:oim_id])
  end

  # You can put the params you want to permit in the empty array.
  # def configure_account_update_params
  #   devise_parameter_sanitizer.for(:account_update) << :attribute
  # end

  # The path used after sign up.
  # def after_sign_up_path_for(resource)
  #   super(resource)
  # end

  # The path used after sign up for inactive accounts.
  # def after_inactive_sign_up_path_for(resource)
  #   super(resource)
  # end

  def set_sign_up_warning
    return unless is_flashing_format?
    flash_type = @bs4 ? :success : :notice
    flash_message = @bs4 ? :signed_up_bs4 : :signed_up
    set_flash_message flash_type, flash_message, site_name: EnrollRegistry[:enroll_app].setting(:short_name).item
  end

  def enable_bs4_layout
    @bs4 = true
  end

  def enable_updated_layout
    @use_bs4_layout = true
  end

end
