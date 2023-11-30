# frozen_string_literal: true

module BenefitSponsors
  # helper to sanite the value
  module SanitizeHelper
    def sanitize(value)
      ActionController::Base.helpers.sanitize(value)
    end
  end
end