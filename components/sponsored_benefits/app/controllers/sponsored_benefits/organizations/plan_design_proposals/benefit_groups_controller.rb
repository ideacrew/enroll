module SponsoredBenefits
  module Organizations
    class PlanDesignProposals::BenefitGroupsController < ApplicationController
      include SponsoredBenefits::Organizations::PlanDesignHelpers

      def create
        update_benefit_group_attributes if benefit_group.persisted?

        benefit_group.title = "Benefit Group Created for: #{plan_design_organization.legal_name} by #{plan_design_organization.broker_agency_profile.legal_name}"
        benefit_group.elected_plans = benefit_group.elected_plans_by_option_kind

        if benefit_group.sole_source?
          benefit_group.build_relationship_benefits
          benefit_group.estimate_composite_rates
        else
          # TODO - Handle when composite tier models merged
          # benefit_group.build_composite_tier_contributions
        end

        benefit_group.set_bounding_cost_plans

        if plan_design_proposal.save
          render json: { url: new_organizations_plan_design_proposal_plan_review_path(plan_design_proposal) }
        else
          flash[:error] = "Something went wrong"
        end
      end

      private
        def update_benefit_group_attributes
          if benefit_group.sole_source?
            benefit_group.composite_tier_contributions.destroy_all
          else
            benefit_group.relationship_benefits.destroy_all
          end

          benefit_group.update_attributes(benefit_group_params)
        end
    end
  end
end
