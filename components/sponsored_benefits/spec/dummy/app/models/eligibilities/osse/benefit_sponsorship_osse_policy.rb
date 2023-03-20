# frozen_string_literal: true

module Eligibilities
  module Osse
    # Value model
    class BenefitSponsorshipOssePolicy < Eligibilities::Osse::Value
      include Mongoid::Document
      include Mongoid::Timestamps
      # include ::EventSource::Command
      # include Dry::Monads[:result, :do, :try]
      # include GlobalID::Identification
      # include Eligibilities::Eventable

      RELAXED_RULES = [
        :minimum_participation_rule,
        :all_contribution_levels_min_met,
        :benefit_application_fte_count
      ].freeze

      embedded_in :grant, class_name: "::Eligibilities::Osse::Grant"

      field :value, type: String

      validates_presence_of :value

      def run
        RELAXED_RULES.include?(key)
      end
    end
  end
end
