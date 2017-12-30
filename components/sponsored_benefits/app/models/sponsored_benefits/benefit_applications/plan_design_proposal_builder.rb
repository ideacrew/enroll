module SponsoredBenefits
  module BenefitApplications
    class PlanDesignProposalBuilder

      attr_reader :plan_design_organization

      def initialize(employer_profile)
        @plan_design_organization = SponsoredBenefits::Organizations::PlanDesignOrganization.find_by_employer_profile(employer_profile)
        @plan_design_proposal = SponsoredBenefits::Organizations::PlanDesignOrganization.plan_design_proposals.build
      end

      def add_plan_design_proposal
      end

      def add_benefit_sponsorship
      end

      def add_benefit_application
      end

      def plan_design_proposal
        # Perform Validations
        raise "required employer permission" unless has_access?
        raise ""

        @plan_design_proposal
      end

      private

      # PlanDesigner access level to EmployerProfile:
      #   Full Broker Hired Access
      #   One-time Quote Access
      #   No Access
      def has_access?
      end

    end
  end
end
