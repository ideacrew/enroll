# frozen_string_literal: true

# Handles custom exceptions if enabled, otherwise just loads files from the public folder
class ExceptionsController < ApplicationController
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
