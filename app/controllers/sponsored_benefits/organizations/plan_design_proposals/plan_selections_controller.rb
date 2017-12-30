module SponsoredBenefits
  module Organizations
    class PlanDesignProposals::PlanSelectionsController < ApplicationController

      def new
        plan_design_form.build_benefit_group
      end

      private
      helper_method :plan_design_form, :plan_design_organization, :plan_design_proposal

      def plan_design_proposal
        @plan_design_proposal ||= SponsoredBenefits::Organizations::PlanDesignProposal.find(params[:plan_design_proposal_id])
      end

      def plan_design_organization
        @plan_design_organization ||= plan_design_proposal.plan_design_organization
      end

      def plan_design_form
        SponsoredBenefits::Forms::PlanDesignProposal.new(organization: plan_design_organization, proposal_id: params[:plan_design_proposal_id])
      end
    end
  end
end
