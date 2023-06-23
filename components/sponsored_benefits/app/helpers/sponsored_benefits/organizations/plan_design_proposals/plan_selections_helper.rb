# frozen_string_literal: true

module SponsoredBenefits
  module Organizations
    module PlanDesignProposals
      # helper for plan selections
      module PlanSelectionsHelper
        def employer_contribution_percent_minimum_for_application(plan_design_proposal)
          return 0 if plan_design_proposal.all_contribution_levels_min_met_relaxed?

          plan_design_organization = plan_design_proposal.plan_design_organization
          employer_contribution_percent_minimum_for_application_start_on(plan_design_proposal.effective_date.to_date, plan_design_organization.is_renewing_employer?)
        end

        def family_contribution_percent_minimum_for_application(plan_design_proposal)
          return 0 if plan_design_proposal.all_contribution_levels_min_met_relaxed?

          plan_design_organization = plan_design_proposal.plan_design_organization
          family_contribution_percent_minimum_for_application_start_on(plan_design_proposal.effective_date.to_date, plan_design_organization.is_renewing_employer?)
        end
      end
    end
  end
end
