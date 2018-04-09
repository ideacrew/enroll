require_dependency "benefit_sponsors/application_controller"

module BenefitSponsors
  class Profiles::RegistrationsController < ApplicationController

    include Concerns::ProfileRegistration
    before_action :initialize_agency, only: [:create]

    def new
      @agency= BenefitSponsors::Organizations::Forms::Profile.new(profile_type: profile_type)

      respond_to do |format|
        format.html
        format.js
      end
    end

    def create
      begin
        saved, result_url = @agency.save(current_user, params[:agency])
        result_url = self.send(result_url)
        if saved
          if is_employer_profile?
            create_sso_account(current_user, current_user.person, 15, "employer") do
            end
          else
            flash[:notice] = "Your registration has been submitted. A response will be sent to the email address you provided once your application is reviewed."
          end
          redirect_to result_url
          return
        end
        redirect_to default_url
      rescue Exception => e
        flash[:error] = e.message
        redirect_to default_url
      end
    end

    private

    def profile_type
      @profile_type = params[:profile_type] || params[:agency][:profile_type]
    end

    def initialize_agency
      return if params[:agency].blank?
      params[:agency].permit!
      @agency= BenefitSponsors::Organizations::Forms::Profile.new(params[:agency])
    end

    def default_url
      if is_employer_profile?
        sponsor_new_registration_url
      else
        broker_new_registration_url
      end
    end

    def is_employer_profile?
      profile_type == "benefit_sponsor"
    end
  end
end
