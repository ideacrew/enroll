# frozen_string_literal: true

module SponsoredBenefits
  module Operations
    module BenefitSponsorships
      module BqtOsseEligibilities
        # Overrides top level evidence_configuration for feature specific configurations
        class OsseEvidenceConfiguration < ::Operations::Eligible::EvidenceConfiguration
          def key
            :bqt_osse_evidence
          end

          def title
            "BQT Osse Evidence"
          end
        end
      end
    end
  end
end
