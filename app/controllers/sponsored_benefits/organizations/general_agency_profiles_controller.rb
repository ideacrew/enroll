require_dependency "sponsored_benefits/application_controller"

module SponsoredBenefits
  class Organizations::GeneralAgencyProfilesController < ApplicationController

    def index
      # Add pundit Authourization
      @form = SponsoredBenefits::Forms::GeneralAgencyManager.for_index(
        action_id: params[:action_id],
        broker_agency_profile_id: params[:broker_agency_profile_id],
        plan_design_organization_id: params[:id]
      )
    end

    def assign
      # Add pundit Authourization
      @form = SponsoredBenefits::Forms::GeneralAgencyManager.for_assign(
        plan_design_organization_ids: [params[:id]] || params[:ids],
        broker_agency_profile_id: params[:broker_agency_profile_id],
        general_agency_profile_id: params[:general_agency_profile_id]
      )

      if @form.assign
        flash[:success] = "Succesfully Assigned General Agency"
      else
        flash[:error] = "Assignment failed: #{@form.errors.full_messages.join(",")}"
      end
      redirect_to sponsored_benefits.employers_organizations_broker_agency_profile_path(id: @form.broker_agency_profile_id)
    end

    def fire
      # Add pundit Authourization
      @form = SponsoredBenefits::Forms::GeneralAgencyManager.for_fire(
        plan_design_organization_id: params[:id],
        broker_agency_profile_id: params[:broker_agency_profile_id]
      )
      if @form.fire!
        flash[:notice] = "Succesfully Fired General Agency"
      else
        flash[:notice] = "Clear Assignment failed: #{@form.errors.full_messages.join(",")}"
      end
      redirect_to sponsored_benefits.employers_organizations_broker_agency_profile_path(id: @form.broker_agency_profile_id)
    end
  end
end
