# frozen_string_literal: true

module BenefitSponsors
  module BenefitSponsorships
    module ShopOsseEligibility
      # Grant model
      class Grant
        include Mongoid::Document
        include Mongoid::Timestamps
        include ::Eligible::Concerns::Grant
      end
    end
  end
end
