# frozen_string_literal: true
module BenefitSponsors
  module BenefitSponsorships
    module ShopOsseEligibility
      # Eligibility model
      class Eligibility
        include Mongoid::Document
        include Mongoid::Timestamps
        include ::Eligble::Concerns::Eligibility
      end
    end
  end
end
