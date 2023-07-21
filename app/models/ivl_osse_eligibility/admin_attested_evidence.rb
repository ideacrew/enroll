# frozen_string_literal: true

module IvlOsseEligibility
  # Admin attested Evidence model for ivl osse eligibility
  class AdminAttestedEvidence
    include Mongoid::Document
    include Mongoid::Timestamps
    include ::Eligible::Concerns::Evidence
  end
end