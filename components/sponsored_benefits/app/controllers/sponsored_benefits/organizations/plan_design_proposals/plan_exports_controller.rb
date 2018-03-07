module SponsoredBenefits
  module Organizations
    class PlanDesignProposals::PlanExportsController < ApplicationController
      include SponsoredBenefits::Organizations::PlanDesignHelpers

      def new
        @plan_design_organization = plan_design_organization
        @benefit_group = benefit_group
        @census_employees = sponsorship.census_employees

        if @benefit_group
          @plan = @benefit_group.reference_plan
          @employer_contribution_amount = @benefit_group.monthly_employer_contribution_amount
          @benefit_group_costs = @benefit_group.employee_costs_for_reference_plan
          @qhps = ::Products::QhpCostShareVariance.find_qhp_cost_share_variances(plan_array(@plan), plan_design_proposal.effective_date.year, "Health")
        end

        render pdf: 'plan_details_export',
               template: 'sponsored_benefits/organizations/plan_design_proposals/plan_exports/_plan_details.html.erb',
               disposition: 'attachment',
               locals: { benefit_group: @benefit_group, plan_design_proposal: plan_design_proposal, qhps: @qhps, plan: @plan, visit_types: visit_types, sbc_included: sbc_included }
      end

      private
        def sbc_included
          params[:sbc_included] == 'true'
        end
    end
  end
end
