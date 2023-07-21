# frozen_string_literal: true

module IvlOsseEligibility
  # Eligibility model for ivl osse
  class Eligibility
    include Mongoid::Document
    include Mongoid::Timestamps
    include ::Eligible::Concerns::Eligibility

    embeds_one :ivl_osse_evidence, class_name: '::IvlOsseEligibility::AdminAttestedEvidence'
    embeds_one :hc4cc_subsidy_grant, class_name: '::IvlOsseEligibility::Grant'

  end
end