module BenefitSponsors
  class Profiles::EmployerProfilesController < ApplicationController
    before_action :get_site_key
    def new
      if @site_key == :dc
        @profile = Organizations::AcaShopDcEmployerProfile.new
      elsif @site_key == :cca
        @profile = Organizations::AcaShopCcaEmployerProfile.new
      end
      @sponsor = Organizations::Factories::BenefitSponsorFactory.new(@profile, nil)
    end

    def create
    end

    def update
      sanitize_office_locations_params

      @general_organization = BenefitSponsors::Organizations::Organization.find(params[:id])
      @employer_profile = @general_organization.profiles.first
      @orga_office_locations_dup = @general_organization.office_locations.as_json
    end

    def sanitize_office_locations_params
    end

    private

    def get_site_key
      @site_key = self.class.superclass.current_site.site_key
    end
  end
end
