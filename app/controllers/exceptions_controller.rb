# frozen_string_literal: true

# Handles custom exceptions if enabled, otherwise just loads files from the public folder
class ExceptionsController < ApplicationController

  ## Devise filters
  skip_before_action :require_login, unless: :authentication_not_required?
  skip_before_action :authenticate_user_from_token!
  skip_before_action :authenticate_me!

  # for i18L
  skip_before_action :set_locale

  # for current_user
  skip_before_action :set_current_user
  def show
    status_code = params[:code] || 500
    if EnrollRegistry.feature_enabled?(:custom_exceptions_controller)
      render 'show', status: status_code
    else
      render file: "public/#{status_code}.html",
             status: status_code,
             layout: false
    end
  end
end
