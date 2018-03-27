module BenefitSponsors
  class Profiles::EmployerProfilesController < ApplicationController
    before_action :get_site_key
    before_action :initiate_employer_profile, only: [:create]

    def new
      @sponsor = Organizations::Factories::BenefitSponsorFactory.new(nil)
    end

    def create
      begin
        organization_saved, pending = @sponsor.save(current_user)
      rescue Exception => e
        flash[:error] = e.message
        render action: "new"
        return
      end
      if organization_saved
        @person = current_user.person
        create_sso_account(current_user, current_user.person, 15, "employer") do
          if pending
            # flash[:notice] = 'Your Employer Staff application is pending'
            render action: 'show_pending'
          else
            # employer_account_creation_notice if @sponsor.employer_profile.present?
            # redirect_to employers_employer_profile_path(@organization.employer_profile, tab: 'home')
          end
        end
      else
        render action: "new"
      end
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

    def initiate_employer_profile
      params[:sponsor].permit!
      if @site_key == :dc
        @profile = Organizations::AcaShopDcEmployerProfile.new
      elsif @site_key == :cca
        @profile = Organizations::AcaShopCcaEmployerProfile.new
      end
      @sponsor = Organizations::Factories::BenefitSponsorFactory.new(@profile, params[:sponsor])
    end
  end
end
