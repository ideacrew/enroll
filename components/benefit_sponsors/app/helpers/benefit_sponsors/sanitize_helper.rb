# frozen_string_literal: true

module BenefitSponsors
  # helper to sanite the value
  module SanitizeHelper
    def sanitize(value)
      return value unless value.is_a?(String)

      ActionController::Base.helpers.sanitize(value)
    end
  end
end