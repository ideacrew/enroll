module SponsoredBenefits
  module Organizations
    class PlanDesignProposals::ContributionsController < ApplicationController
      include SponsoredBenefits::Organizations::PlanDesigners
      include SponsoredBenefits::Organizations::BenefitGroupAccessors

      def index
        @plan = ::Plan.find(benefit_group.reference_plan_id)
        if benefit_group.sole_source?
          benefit_group.build_estimated_composite_rates
        end
        benefit_group.set_bounding_cost_plans
        @employer_contribution_amount = benefit_group.monthly_employer_contribution_amount(@plan)
        @min_employee_cost = benefit_group.monthly_min_employee_cost
        @max_employee_cost = benefit_group.monthly_max_employee_cost

        @benefit_group_costs = benefit_group.employee_costs_for_reference_plan
      end
    end
  end
end
