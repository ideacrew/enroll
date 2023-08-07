# frozen_string_literal: true

module BenefitSponsors
  module BenefitSponsorships
    module ShopOsseEligibility
      # Evidence model
      class AdminAttestedEvidence
        include Mongoid::Document
        include Mongoid::Timestamps
        include ::Eligible::Concerns::Evidence
      end
    end
  end
end
