module SponsoredBenefits
  module Organizations
    module PlanDesignHelpers
      extend ActiveSupport::Concern

      included do
        helper_method :plan_design_form, :plan_design_organization, :plan_design_proposal, :selected_carrier_level, :visit_types
      end

      private
        def plan_design_proposal
          @plan_design_proposal ||= SponsoredBenefits::Organizations::PlanDesignProposal.find(params[:plan_design_proposal_id])
        end

        def plan_design_organization
          @plan_design_organization ||= if params.key? :plan_design_organization_id
            PlanDesignOrganization.find(params[:plan_design_organization_id])
          else
            plan_design_proposal.plan_design_organization
          end
        end

        def sponsorship
          @sponsorship ||= plan_design_proposal.profile.benefit_sponsorships.first
        end

        def benefit_group
          @benefit_group ||= sponsorship.benefit_applications.first.benefit_groups.first || sponsorship.benefit_applications.first.benefit_groups.build(benefit_group_params)
        end

        def plan_design_form
          SponsoredBenefits::Forms::PlanDesignProposal.new(organization: plan_design_organization, proposal_id: params[:plan_design_proposal_id])
        end

        def selected_carrier_level
          @selected_carrier_level ||= params[:selected_carrier_level]
        end

        def visit_types
          @visit_types ||= ::Products::Qhp::VISIT_TYPES
        end

        def plan_array(plan)
           ::Plan.where(:_id => { '$in': [plan.id] } ).map(&:hios_id)
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
