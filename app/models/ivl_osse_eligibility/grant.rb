# frozen_string_literal: true

module IvlOsseEligibility
  # Grant model for ivl osse eligibility
  class Grant
    include Mongoid::Document
    include Mongoid::Timestamps
    include ::Eligible::Concerns::Grant
  end
end
