require_dependency "sponsored_benefits/application_controller"

module SponsoredBenefits
  class Organizations::BrokerAgencyProfilesController < ApplicationController
    include DataTablesAdapter
    include ::Config::SiteModelConcern
    before_action :find_profile, :general_agency_profiles, only: [:employers]

    def employers
      # This should be index action in plan design organizations controller
      Rails.logger.warn("Attempted to access employers with no profile present.") if is_shop_or_fehb_market_enabled? && @profile.blank?
      head :bad_request unless is_shop_or_fehb_market_enabled? && @profile.present?
      @datatable = klass.new(profile_id: @profile._id) if @profile.present?
    end

  private

    def find_profile
      @profile = BenefitSponsors::Organizations::BrokerAgencyProfile.find(params[:id]) || BenefitSponsors::Organizations::GeneralAgencyProfile.find(params[:id])
      @provider = provider if @profile
    end

    def general_agency_profiles
      return @general_agency_profiles if defined? @general_agency_profiles
      @general_agency_profiles = BenefitSponsors::Organizations::GeneralAgencyProfile.all
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
