# frozen_string_literal: true

module Users
  class PasswordsController < Devise::PasswordsController
    before_action :confirm_identity, only: [:create]
    layout 'bootstrap_4'
    include ActionView::Helpers::TranslationHelper
    include L10nHelper

    before_action :enable_bs4_layout if EnrollRegistry.feature_enabled?(:bs4_consumer_flow)

    rescue_from 'Mongoid::Errors::DocumentNotFound', with: :user_not_found
    def create
      if verify_recaptcha_if_needed
        self.resource = resource_class.send_reset_password_instructions(resource_params)
        yield resource if block_given?
        if successfully_sent?(resource)
          resource.security_question_responses.destroy_all
          show_generic_forgot_password_text

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
      show_generic_forgot_password_text
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

    def show_generic_forgot_password_text
      return unless EnrollRegistry.feature_enabled?(:generic_forgot_password_text)
      flash[:notice] = l10n('devise.passwords.new.generic_forgot_password_text')
    end

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
      return true if current_user&.has_role?('hbx_staff')
      if user.identity_confirmed_token.present? && user.identity_confirmed_token != params[:user][:identity_confirmed_token]
        flash[:error] = "Something went wrong, please try again"
        redirect_to new_user_password_path
        false
      end
    end

    protected

    def after_resetting_password_path_for(_resource_name)
      root_url
    end

    def enable_bs4_layout
      @bs4 = true
    end
  end
end
