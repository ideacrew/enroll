require_dependency "benefit_sponsors/application_controller"

module BenefitSponsors
  class Profiles::RegistrationsController < ApplicationController
  	before_action :get_site_key
    before_action :initiate_agency, only: [:create]

    def new
      @agency = Object.const_get("BenefitSponsors::Organizations::Factories::#{class_name}ProfileFactory".classify).new(nil)

      respond_to do |format|
        format.html
        format.js
      end
    end

    def create
      notice = "Your registration has been submitted. A response will be sent to the email address you provided once your application is reviewed."
      if @agency.save
        flash[:notice] = notice
        profile_type = @agency.class.to_s.split("::").last.gsub("ProfileFactory","").underscore
        redirect_to new_profiles_registration_path(:profile_type => profile_type)
      else
        render 'new'
      end
    end

    private

    def get_site_key
      @site_key = self.class.current_site.site_key
    end

    def class_name
      (params[:profile_type] || params[:agency][:profile_type]).camelcase
    end

    def initiate_agency
      return if params[:agency].blank?
      params[:agency].permit!
      @profile = Object.const_get("BenefitSponsors::Organizations::#{class_name}Profile".classify).new(nil)
      @agency = Object.const_get("BenefitSponsors::Organizations::Factories::#{class_name}ProfileFactory".classify).new(@profile, params[:agency].except(:profile_type))
    end
  end
end
