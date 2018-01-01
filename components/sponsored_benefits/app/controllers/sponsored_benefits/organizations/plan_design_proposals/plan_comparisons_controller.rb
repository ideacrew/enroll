module SponsoredBenefits
  module Organizations
    class PlanDesignProposals::PlanComparisonsController < ApplicationController

        def new
          @qhps = ::Products::QhpCostShareVariance.find_qhp_cost_share_variances(requested_plans, plan_design_proposal.effective_date.year, "Health")
          @sort_by = params[:sort_by].rstrip
          # Sorting by the same parameter alternates between ascending and descending
          @order = @sort_by == session[:sort_by_copay] ? -1 : 1
          session[:sort_by_copay] = @order == 1 ? @sort_by : ''
          if @sort_by && @sort_by.length > 0
            @sort_by = @sort_by.strip
            sort_array = []
            @qhps.each do |qhp|
              sort_array.push( [qhp, get_visit_cost(qhp,@sort_by)]  )
            end
            sort_array.sort!{|a,b| a[1]*@order <=> b[1]*@order}
            @qhps = sort_array.map{|item| item[0]}
          end
        end

        def export

        end

        private
        helper_method :plan_design_form, :plan_design_organization, :plan_design_proposal, :visit_types

        def plan_design_proposal
          @plan_design_proposal ||= SponsoredBenefits::Organizations::PlanDesignProposal.find(params[:plan_design_proposal_id])
        end

        def plan_design_organization
          @plan_design_organization ||= plan_design_proposal.plan_design_organization
        end

        def requested_plans
          @plans ||= ::Plan.where(:_id => { '$in': params[:plans] } ).map(&:hios_id)
        end

        def visit_types
          ::Products::Qhp::VISIT_TYPES
        end
    end
  end
end
