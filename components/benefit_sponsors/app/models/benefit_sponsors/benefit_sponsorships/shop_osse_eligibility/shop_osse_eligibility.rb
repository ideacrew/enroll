# frozen_string_literal: true

module BenefitSponsors
  module BenefitSponsorships
    module ShopOsseEligibility
      # Eligibility model
      class ShopOsseEligibility
        include Mongoid::Document
        include Mongoid::Timestamps
        include ::Eligible::Concerns::Eligibility


        embeds_many :evidences,  class_name: '::BenefitSponsors::BenefitSponsorships::ShopOsseEligibility::AdminAttestedEvidence'
        embeds_many :grants, class_name: '::BenefitSponsors::BenefitSponsorships::ShopOsseEligibility::ShopOsseGrant'
      end
    end
  end
end
