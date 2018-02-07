module SponsoredBenefits
  module BenefitMarkets
    class SponsorEligibilityPolicy
      include Mongoid::Document
      include Mongoid::Timestamps

      ## sponsor eligibility rules
      # 0 < roster size < 50
      # roster member non-owner > 0

    end
  end
end
