# frozen_string_literal: true

module Operations
  module Eligible
    # Configurations for the Evidence
    class EvidenceConfiguration
      def key
        :evidence
      end

      def title
        "Evidence"
      end

      def to_state_for(values, from_state)
        case values[:evidence_value]
        when "true"
          :approved
        when "false"
          case from_state
          when :not_approved, :approved, :denied
            :denied
          else
            :not_approved
          end
        end
      end

      def is_eligible?(state)
        ::Eligible::Evidence::ELIGIBLE_STATUSES.include?(state)
      end
    end
  end
end
