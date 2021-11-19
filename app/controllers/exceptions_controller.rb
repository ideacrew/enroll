# frozen_string_literal: true

# Handles custom exceptions if enabled, otherwise just loads files from the public folder
class ExceptionsController < ApplicationController
  def show
    status_code = params[:code] || 500
    render status_code.to_s, status: status_code and return if EnrollRegistry.feature_enabled?(:custom_exceptions_controller)
    render file: "public/#{status_code}.html", status: status_code, layout: false and return
  end
end
