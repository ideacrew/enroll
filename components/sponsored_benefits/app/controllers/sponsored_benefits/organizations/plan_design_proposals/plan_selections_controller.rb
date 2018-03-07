module SponsoredBenefits
  module Organizations
    class PlanDesignProposals::PlanSelectionsController < ApplicationController
      include SponsoredBenefits::Organizations::PlanDesignHelpers

      before_action :published_plans_are_view_only

      def new
        plan_design_form.build_benefit_group
      end

      private

      def published_plans_are_view_only
        if plan_design_proposal.published?
          redirect_to organizations_plan_design_proposal_path(plan_design_proposal)
        end
      end
    end
  end
end
