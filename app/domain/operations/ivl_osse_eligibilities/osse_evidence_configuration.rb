# frozen_string_literal: true

module Operations
  module IvlOsseEligibilities
    class OsseEvidenceConfiguration < ::Operations::Eligible::EvidenceConfiguration
      def self.key
        :ivl_osse_evidence
      end

      def self.title
        "Ivl Osse Evidence"
      end
    end
  end
end
