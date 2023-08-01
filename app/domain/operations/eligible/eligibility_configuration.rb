module Operations
  module Eligible
    class EligibilityConfiguration
      def self.key
        :eligibility
      end

      def self.title
        "Eligibility"
      end

      def self.grants
        %i[subsidy_grant]
      end

      def self.to_state_for(evidence_state)
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
