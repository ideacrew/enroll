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

      def roles_for_determination
        coverage_household.active_individual_enrollments.flat_map(&:hbx_enrollment_members).map(&:person).map(&:consumer_role)
      end

      def determine_next_state
        return(:unverified) if roles_for_determination.any?(&:verifications_pending?)
        return(:enrolled_contingent) if roles_for_determination.any?(&:verifications_outstanding?)
        :enrolled
      end
    end
  end
end
