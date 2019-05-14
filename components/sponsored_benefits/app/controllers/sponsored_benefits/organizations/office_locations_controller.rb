require_dependency "sponsored_benefits/application_controller"

module SponsoredBenefits
  class Organizations::OfficeLocationsController < ApplicationController
    class SlugLocationOwner
      def office_locations
        []
      end

      def office_locations_attributes=(vals)
      end
    end

    def new
      params.permit([:child_index, :parent_object])
      @child_index = params[:child_index]
      @parent_object = params[:parent_object]
      @slug_owner = SlugLocationOwner.new
      @office_location = SponsoredBenefits::Organizations::OfficeLocation.new
      @office_location.build_address
      @office_location.build_phone
      respond_to do |format|
        format.js
      end
    end

    def delete
      params.permit(:id, :plan_org_id)
      plan_design_org = SponsoredBenefits::Organizations::PlanDesignOrganization.find(params[:plan_org_id])
      office_location = plan_design_org.office_locations.find(params[:id])
      office_location.destroy
      plan_design_org.save!
      respond_to do |format|
        url = edit_organizations_plan_design_organization_path(plan_design_org, profile_id: plan_design_org.broker_agency_profile.id.to_s)
        format.html {redirect_to url}
      end
    end
  end
end
