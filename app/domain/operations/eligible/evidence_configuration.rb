module Operations
  module Eligible
    class EvidenceConfiguration
      def self.key
        :evidence
      end

      def self.title
        "Evidence"
      end

      def self.to_state_for(values, from_state)
        case values[:evidence_value]
        when "true"
          :approved
        when "false"
          case from_state
          when :approved
            :denied
          when :initial
            return :initial unless values[:evidence_record]
            :denied
          end
        end
      end

      def self.is_eligible?(state)
        ::Eligible::Evidence::ELIGIBLE_STATUSES.include?(state)
      end
    end
  end
end
