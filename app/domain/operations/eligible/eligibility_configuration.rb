# frozen_string_literal: true

module Operations
  module Eligible
    # Configurations for the Eligibility
    class EligibilityConfiguration
      def key
        :eligibility
      end

      def title
        "Eligibility"
      end

      def grants
        %i[subsidy_grant]
      end

      def to_state_for(evidence_state)
        case evidence_state
        when :approved, :denied
          :published
        else
          :initial
        end
      end
    end
  end
end
