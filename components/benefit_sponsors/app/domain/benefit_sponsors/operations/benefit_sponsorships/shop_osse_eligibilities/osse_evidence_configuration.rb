# frozen_string_literal: true

module BenefitSponsors
  module Operations
    module BenefitSponsorships
      module ShopOsseEligibilities
        # Overrides top level evidence_configuration for feature specific configurations
        class OsseEvidenceConfiguration < ::Operations::Eligible::EvidenceConfiguration
          def self.key
            :shop_osse_evidence
          end

          def self.title
            "Shop Osse Evidence"
          end
        end
      end
    end
  end
end
