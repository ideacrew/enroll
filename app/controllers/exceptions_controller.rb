# frozen_string_literal: true

# Handles custom exceptions if enabled, otherwise just loads files from the public folder
class ExceptionsController < ApplicationController
  before_action :recover_exception_code

  ## Devise filters
  skip_before_action :require_login, unless: :authentication_not_required?
  skip_before_action :authenticate_user_from_token!
  skip_before_action :authenticate_me!

  # for i18L
  skip_before_action :set_locale
  # for current_user
  skip_before_action :set_current_user
  def show
    render 'show', status: @exception_code if EnrollRegistry.feature_enabled?(:custom_exceptions_controller)

    render file: "public/#{@exception_code}.html", status: @exception_code, layout: false
  end

  private

  def recover_exception_code
    exception = request.env["action_dispatch.exception"]
    @exception_code = ActionDispatch::ExceptionWrapper.new(request.env, exception).status_code
  end
end
