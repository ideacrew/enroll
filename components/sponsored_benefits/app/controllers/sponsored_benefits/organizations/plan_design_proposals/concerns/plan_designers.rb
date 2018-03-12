module SponsoredBenefits
  module Organizations
    module PlanDesigners
      extend ActiveSupport::Concern

      included do
        helper_method :plan_design_form, :plan_design_organization, :plan_design_proposal
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

        def plan_design_form
          SponsoredBenefits::Forms::PlanDesignProposal.new(organization: plan_design_organization, proposal_id: params[:plan_design_proposal_id])
        end

        def sponsorship
          @sponsorship ||= plan_design_proposal.profile.benefit_sponsorships.first
        end

        def plan_array(plan)
           ::Plan.where(:_id => { '$in': [plan.id] } ).map(&:hios_id)
        end
    end
  end
end
