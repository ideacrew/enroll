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
        :minimum_participation_rule_relaxed,
        :all_contribution_levels_min_met_relaxed,
        :benefit_application_fte_count_relaxed
      ].freeze

      embedded_in :grant, class_name: "::Eligibilities::Osse::Grant"

      field :value, type: String

      validates_presence_of :value

      def run(_model_instance)
        return true if RELAXED_RULES.include?(key)
        false
      end
    end
  end
end
