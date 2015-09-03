module RuleSet
  module CoverageHousehold
    class IndividualMarketVerification
      attr_reader :coverage_household

      def initialize(c_household)
        @coverage_household = c_household
      end

      def applicable?
        coverage_household.active_individual_enrollments.any?
      end
    end
  end
end
