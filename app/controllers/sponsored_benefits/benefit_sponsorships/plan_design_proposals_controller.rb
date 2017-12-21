require_dependency "sponsored_benefits/application_controller"

module SponsoredBenefits
  class BenefitSponsorships::PlanDesignProposalsController < ApplicationController
    before_action :set_benefit_sponsorships_plan_design_proposal, only: [:show, :edit, :update, :destroy]

    # GET /benefit_sponsorships/plan_design_proposals
    def index
      @benefit_sponsorships_plan_design_proposals = BenefitSponsorships::PlanDesignProposal.all
    end

    # GET /benefit_sponsorships/plan_design_proposals/1
    def show
    end

    # GET /benefit_sponsorships/plan_design_proposals/new
    def new
      @benefit_sponsorships_plan_design_proposal = BenefitSponsorships::PlanDesignProposal.new
    end

    # GET /benefit_sponsorships/plan_design_proposals/1/edit
    def edit
    end

    # POST /benefit_sponsorships/plan_design_proposals
    def create
      @benefit_sponsorships_plan_design_proposal = BenefitSponsorships::PlanDesignProposal.new(benefit_sponsorships_plan_design_proposal_params)

      if @benefit_sponsorships_plan_design_proposal.save
        redirect_to @benefit_sponsorships_plan_design_proposal, notice: 'Plan design proposal was successfully created.'
      else
        render :new
      end
    end

    # PATCH/PUT /benefit_sponsorships/plan_design_proposals/1
    def update
      if @benefit_sponsorships_plan_design_proposal.update(benefit_sponsorships_plan_design_proposal_params)
        redirect_to @benefit_sponsorships_plan_design_proposal, notice: 'Plan design proposal was successfully updated.'
      else
        render :edit
      end
    end

    # DELETE /benefit_sponsorships/plan_design_proposals/1
    def destroy
      @benefit_sponsorships_plan_design_proposal.destroy
      redirect_to benefit_sponsorships_plan_design_proposals_url, notice: 'Plan design proposal was successfully destroyed.'
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_benefit_sponsorships_plan_design_proposal
        @benefit_sponsorships_plan_design_proposal = BenefitSponsorships::PlanDesignProposal.find(params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def benefit_sponsorships_plan_design_proposal_params
        params[:benefit_sponsorships_plan_design_proposal]
      end
  end
end
