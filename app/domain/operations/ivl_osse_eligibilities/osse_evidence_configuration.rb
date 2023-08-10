# frozen_string_literal: true

module Operations
  module IvlOsseEligibilities
    # Overrides top level evidence_configuration for ivl osse specific configurations
    class OsseEvidenceConfiguration < ::Operations::Eligible::EvidenceConfiguration
      def key
        :ivl_osse_evidence
      end

      def title
        "Ivl Osse Evidence"
      end
    end
  end
end
