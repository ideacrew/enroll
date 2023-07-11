class Users::PasswordsController < Devise::PasswordsController
  before_action :confirm_identity, only: [:create]
  layout 'bootstrap_4'
  include ActionView::Helpers::TranslationHelper
  include L10nHelper

  rescue_from 'Mongoid::Errors::DocumentNotFound', with: :user_not_found
  def create
    if verify_recaptcha_if_needed
      self.resource = resource_class.send_reset_password_instructions(resource_params)
      yield resource if block_given?
      if successfully_sent?(resource)
        resource.security_question_responses.destroy_all

        respond_to do |format|
          format.html { respond_with({}, location: after_sending_reset_password_instructions_path_for(resource_name)) }
          format.js
        end

      else
        respond_with(resource)
      end
    else
      flash[:error] = "reCAPTCHA verification failed, please try again."
      redirect_to "/users/password/new"
    end
  end

  def user_not_found
    if verify_recaptcha_for_user_not_found
      respond_to do |format|
        format.html { respond_with({}, location: after_sending_reset_password_instructions_path_for(resource_name)) }
        format.js
      end
    else
      redirect_to "/users/password/new"
    end
  end

  private

  def verify_recaptcha_for_user_not_found
    return true unless helpers.forgot_password_recaptcha_enabled?
    verify_recaptcha
  end

  def verify_recaptcha_if_needed
    return true unless helpers.forgot_password_recaptcha_enabled?
    verify_recaptcha(model: @user)
  end

  def user
    @user ||= User.find_by(email: params[:user][:email])
  end

  def confirm_identity
    if current_user && current_user.has_role?('hbx_staff')
      return true
    end
    if user.identity_confirmed_token.present?
      unless user.identity_confirmed_token == params[:user][:identity_confirmed_token]
        flash[:error] = "Something went wrong, please try again"
        redirect_to new_user_password_path
        return false
      end
    end
  end

  protected

  def after_resetting_password_path_for(resource_name)
    root_url
  end
end
