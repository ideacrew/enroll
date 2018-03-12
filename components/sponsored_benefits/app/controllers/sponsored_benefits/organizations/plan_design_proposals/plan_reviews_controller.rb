module SponsoredBenefits
  module Organizations
    class PlanDesignProposals::PlanReviewsController < ApplicationController
      include SponsoredBenefits::Organizations::PlanDesigners
      include SponsoredBenefits::Organizations::BenefitGroupAccessors
      include SponsoredBenefits::Organizations::BenefitPresentationHelpers

      def new
        @plan_design_organization = plan_design_organization
        @benefit_group = benefit_group
        @census_employees = sponsorship.census_employees

        if @benefit_group
          @plan = @benefit_group.reference_plan
          @employer_contribution_amount = @benefit_group.monthly_employer_contribution_amount
          @benefit_group_costs = @benefit_group.employee_costs_for_reference_plan
          @min_employee_cost = benefit_group.monthly_min_employee_cost
          @max_employee_cost = benefit_group.monthly_max_employee_cost
          @qhps = ::Products::QhpCostShareVariance.find_qhp_cost_share_variances(plan_array(@plan), plan_design_proposal.effective_date.year, "Health")
        end
      end

      def show
        @plan_design_organization = plan_design_organization
        @benefit_group = benefit_group
        @census_employees = sponsorship.census_employees

        if @benefit_group
          @plan = @benefit_group.reference_plan
          @employer_contribution_amount = @benefit_group.monthly_employer_contribution_amount
          @benefit_group_costs = @benefit_group.employee_costs_for_reference_plan
          @min_employee_cost = benefit_group.monthly_min_employee_cost
          @max_employee_cost = benefit_group.monthly_max_employee_cost
          @qhps = ::Products::QhpCostShareVariance.find_qhp_cost_share_variances(plan_array(@plan), plan_design_proposal.effective_date.year, "Health")
        end
        render pdf: 'plan_review_export',
               template: 'sponsored_benefits/organizations/plan_design_proposals/plan_reviews/show.html.erb',
               disposition: 'attachment'
      end
    end
  end
end
