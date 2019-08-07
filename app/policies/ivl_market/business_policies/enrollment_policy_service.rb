# frozen_string_literal: true

module IvlMarket
  module BusinessPolicies
    class EnrollmentPolicyService
      attr_reader :enrollment, :policies_applied

      def initialize(policies:, enrollment:)
        @policies = policies
        @enrollment = enrollment
        @policies_applied = []
      end

      def apply_policies
        @policies.each do |policy|
          policy = PoliciesContainer[policy]
          @policies_applied << policy.execute(enrollment)
        end
        @policies_applied
      end
    end
  end
end