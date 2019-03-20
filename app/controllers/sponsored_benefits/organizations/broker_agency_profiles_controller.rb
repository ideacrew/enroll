require_dependency "sponsored_benefits/application_controller"

module SponsoredBenefits
  class Organizations::BrokerAgencyProfilesController < ApplicationController
    include DataTablesAdapter
    before_action :find_profile, :general_agency_profiles, only: [:employers]

    def employers
      # This should be index action in plan design organizations controller
      @datatable = klass.new(profile_id: @profile._id)
    end

  private

    def find_profile
      @broker_agency_profile = ::BrokerAgencyProfile.find(params[:id]) || BenefitSponsors::Organizations::Profile.find(params[:id])
      @provider = @broker_agency_profile.primary_broker_role.person
      @profile = ::BrokerAgencyProfile.find(params[:id]) || ::GeneralAgencyProfile.find(params[:id])
      @profile ||= BenefitSponsors::Organizations::Profile.find(params[:id])
    end

    def is_profile_general_agency?
      @profile.class.to_s == "GeneralAgencyProfile"
    end

    def general_agency_profiles
      return @general_agency_profiles if defined? @general_agency_profiles
      @general_agency_profiles = ::GeneralAgencyProfile.all
    end

    def klass
      if is_profile_general_agency?
        ::Effective::Datatables::GeneralAgencyPlanDesignOrganizationDatatable
      else
        ::Effective::Datatables::BrokerAgencyPlanDesignOrganizationDatatable
      end
    end
  end
end
