module BenefitSponsors
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception

    def self.current_site
      if BenefitSponsors::Site.by_site_key(:dc).present?
        BenefitSponsors::Site.by_site_key(:dc).first
      elsif BenefitSponsors::Site.by_site_key(:cca).present?
        BenefitSponsors::Site.by_site_key(:cca).first
      end
    end

  end
end
