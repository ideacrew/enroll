module SponsoredBenefits
  module Organizations
    class PlanDesignProposals::ContributionsController < ApplicationController

      def index
        sponsorship = plan_design_proposal.profile.benefit_sponsorships.first
        sponsorship.benefit_applications.build(effective_period: sponsorship.initial_enrollment_period)
        temp_benefit_group = sponsorship.benefit_applications.first.benefit_groups.build(benefit_group_params)

        @plan = ::Plan.find(temp_benefit_group.reference_plan_id)
        if benefit_group_is_sole_source?
          temp_benefit_group.build_estimated_composite_rates
        end
        @employer_contribution_amount = temp_benefit_group.monthly_employer_contribution_amount(@plan)
        @min_employee_cost = temp_benefit_group.monthly_min_employee_cost()
        @max_employee_cost = temp_benefit_group.monthly_max_employee_cost
      end

      private
        helper_method :plan_design_proposal

        def plan_design_proposal
          @plan_design_proposal ||= PlanDesignProposal.find(params[:plan_design_proposal_id])
        end

        def benefit_group_is_sole_source?
          params[:benefit_group][:plan_option_kind] == 'sole_source'
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
