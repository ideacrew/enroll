module SponsoredBenefits
  module Organizations
    class PlanDesignProposals::ContributionsController < ApplicationController

      def index
        if benefit_group.sole_source?
          benefit_group.build_estimated_composite_rates
        end
        benefit_group.set_bounding_cost_plans
        @service = PlanCostService.new({benefit_group: benefit_group})

        @employer_contribution_amount = @service.monthly_employer_contribution_amount
        @min_employee_cost = @service.monthly_min_employee_cost
        @max_employee_cost = @service.monthly_max_employee_cost

        @benefit_group_costs = benefit_group.employee_costs_for_reference_plan(@service)
      end

      private
        helper_method :plan_design_proposal, :benefit_group

        def plan_design_proposal
          @plan_design_proposal ||= PlanDesignProposal.find(params[:plan_design_proposal_id])
        end

        def sponsorship
          @sponsorship ||= plan_design_proposal.profile.benefit_sponsorships.first
        end

        def benefit_group
          @benefit_group ||= sponsorship.benefit_applications.first.benefit_groups.build(benefit_group_params)
        end

        def benefit_group_params
          params.require(:benefit_group).permit(
                      :reference_plan_id,
                      :plan_option_kind,
                      relationship_benefits_attributes: [:relationship, :premium_pct, :offered],
                      composite_tier_contributions_attributes: [:composite_rating_tier, :employer_contribution_percent, :offered]
          )
        end
    end
  end
end
