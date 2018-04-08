require_dependency "benefit_sponsors/application_controller"

module BenefitSponsors
  class Profiles::RegistrationsController < ApplicationController
    before_action :initialize_agency, only: [:create]

    def new
      @agency= BenefitSponsors::Organizations::Forms::Profile.new(profile_type: profile_type)

      respond_to do |format|
        format.html
        format.js
      end
    end

    def create
      result, redirection_path = @agency.save(current_user, params[:agency])
      if result
        flash[:notice] = "Your registration has been submitted. A response will be sent to the email address you provided once your application is reviewed."
        redirect_to redirection_path
      else
        render 'new'
      end
    end

    private

    def profile_type
      (params[:profile_type] || params[:agency][:profile_type]).camelcase
    end

    def initialize_agency
      return if params[:agency].blank?
      params[:agency].permit!
      @agency= BenefitSponsors::Organizations::Forms::Profile.new(params[:agency])
    end
  end
end
