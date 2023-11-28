# frozen_string_literal: true

module IvlOsseEligibilities
  # Eligibility model for ivl osse
  class IvlOsseEligibility < ::Eligible::Eligibility
    evidence :ivl_osse_evidence, class_name: "::IvlOsseEligibilities::AdminAttestedEvidence"

    grant :childcare_subsidy_grant, class_name: "::IvlOsseEligibilities::IvlOsseGrant"
  end
end
