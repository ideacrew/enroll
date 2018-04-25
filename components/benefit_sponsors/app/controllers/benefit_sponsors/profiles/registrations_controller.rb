require_dependency "benefit_sponsors/application_controller"

module BenefitSponsors
  class Profiles::RegistrationsController < ApplicationController

    include Concerns::ProfileRegistration
    include Pundit

    before_action :check_employer_staff_role, only: [:new]

    def new
      @agency= BenefitSponsors::Organizations::Forms::RegistrationForm.for_new(profile_type: profile_type)
      authorize @agency
      respond_to do |format|
        format.html
        format.js
      end
    end

    def create
      @agency = BenefitSponsors::Organizations::Forms::RegistrationForm.for_create(registration_params)
      authorize @agency
      begin
        saved, result_url = @agency.save
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
      rescue Exception => e
        flash[:error] = e.message
      end
      redirect_to default_url
    end

    def edit
      @agency = BenefitSponsors::Organizations::Forms::RegistrationForm.for_edit(profile_id: params[:id])
      authorize @agency
    end

    def update
      @agency = BenefitSponsors::Organizations::Forms::RegistrationForm.for_update(registration_params)
      authorize @agency
      sanitize_office_locations_params
      if can_update_profile? # pundit policy
        updated, result_url = @agency.update
        result_url = self.send(result_url)
        if updated
          flash[:notice] = 'Employer successfully Updated.' if is_employer_profile?
          flash[:notice] = 'Broker Agency Profile successfully Updated.' if is_broker_profile?
        else
          org_error_msg = @agency.errors.full_messages.join(",").humanize if @agency.errors.present?

          flash[:error] = "Employer information not saved. #{org_error_msg}."
        end
      else
        flash[:error] = 'You do not have permissions to update the details'
      end
      redirect_to result_url
    end

    private

    def profile_type
      @profile_type = params[:profile_type] || params[:agency][:profile_type] || @agency.profile_type
    end

    def can_update_profile?
      return true # TODO
      (current_user.has_employer_staff_role? && @employer_profile.staff_roles.include?(current_user.person)) || current_user.person.agent?
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

    def is_broker_profile?
      profile_type == "broker_agency"
    end

    def sanitize_office_locations_params
      # TODO - implement in accepts_nested_attributes_for
      params[:agency][:organization][:profile_attributes][:office_locations_attributes].each do |key, location|
        if location && location[:address_attributes]
          location[:is_primary] = (location[:address_attributes][:kind] == 'primary')
        end
      end
    end

    def registration_params
      current_user_id = current_user.present? ? current_user.id : nil
      params[:agency].merge!({
        :profile_id => params["id"],
        :current_user_id => current_user_id
      })
      params[:agency].permit!
    end

    def organization_params
      params[:agency][:organization].permit!
    end

    #checks if person is approved by employer for staff role
    #Redirects to home page of employer profile if approved
    #person with pending/denied approval will be redirected to new registration page
    def check_employer_staff_role
    end
  end
end
