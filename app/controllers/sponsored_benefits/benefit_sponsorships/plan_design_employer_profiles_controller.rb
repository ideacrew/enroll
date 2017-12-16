require_dependency "sponsored_benefits/application_controller"

module SponsoredBenefits
  class BenefitSponsorships::PlanDesignEmployerProfilesController < ApplicationController
    before_action :set_benefit_sponsorships_plan_design_employer_profile, only: [:show, :edit, :update, :destroy]

    # GET /benefit_sponsorships/plan_design_employer_profiles
    def index
      @benefit_sponsorships_plan_design_employer_profiles = BenefitSponsorships::PlanDesignEmployerProfile.all
    end

    # GET /benefit_sponsorships/plan_design_employer_profiles/1
    def show
    end

    # GET /benefit_sponsorships/plan_design_employer_profiles/new
    def new
      @benefit_sponsorships_plan_design_employer_profile = BenefitSponsorships::PlanDesignEmployerProfile.new
    end

    # GET /benefit_sponsorships/plan_design_employer_profiles/1/edit
    def edit
    end

    # POST /benefit_sponsorships/plan_design_employer_profiles
    def create
      @benefit_sponsorships_plan_design_employer_profile = BenefitSponsorships::PlanDesignEmployerProfile.new(benefit_sponsorships_plan_design_employer_profile_params)

      if @benefit_sponsorships_plan_design_employer_profile.save
        redirect_to @benefit_sponsorships_plan_design_employer_profile, notice: 'Plan design employer profile was successfully created.'
      else
        render :new
      end
    end

    # PATCH/PUT /benefit_sponsorships/plan_design_employer_profiles/1
    def update
      if @benefit_sponsorships_plan_design_employer_profile.update(benefit_sponsorships_plan_design_employer_profile_params)
        redirect_to @benefit_sponsorships_plan_design_employer_profile, notice: 'Plan design employer profile was successfully updated.'
      else
        render :edit
      end
    end

    # DELETE /benefit_sponsorships/plan_design_employer_profiles/1
    def destroy
      @benefit_sponsorships_plan_design_employer_profile.destroy
      redirect_to benefit_sponsorships_plan_design_employer_profiles_url, notice: 'Plan design employer profile was successfully destroyed.'
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_benefit_sponsorships_plan_design_employer_profile
        @benefit_sponsorships_plan_design_employer_profile = BenefitSponsorships::PlanDesignEmployerProfile.find(params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def benefit_sponsorships_plan_design_employer_profile_params
        params.require(:benefit_sponsorships_plan_design_employer_profile).permit(:entity_kind, :sic_code, :legal_name, :dba, :entity_kind)
      end
  end
end
