require_dependency "sponsored_benefits/application_controller"

module SponsoredBenefits
  class Organizations::BrokerAgencyProfilesController < ApplicationController
    include DataTablesAdapter
    before_action :find_profile, only: [:employers]

    def employers
      # This should be index action in plan design organizations controller
      @datatable = ::Effective::Datatables::PlanDesignOrganizationDatatable.new(profile_id: @profile._id, is_general_agency?: is_profile_general_agency?)
    end

  private

    def find_profile
      @profile = ::BrokerAgencyProfile.find(params[:id]) || ::GeneralAgencyProfile.find(params[:id])
      @profile ||= BenefitSponsors::Organizations::Profile.find(params[:id])
    end

    def is_profile_general_agency?
      @profile.class.to_s == "GeneralAgencyProfile"
    end
  end
end
