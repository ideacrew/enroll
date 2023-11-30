module BenefitSponsors
  module SanitizeHelper
    def sanitize(value)
      ActionController::Base.helpers.sanitize(value)
    end
  end
end