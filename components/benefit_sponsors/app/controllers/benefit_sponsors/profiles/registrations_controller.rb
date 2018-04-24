require_dependency "benefit_sponsors/application_controller"

module BenefitSponsors
  class Profiles::RegistrationsController < ApplicationController

    include Concerns::ProfileRegistration
    before_action :initialize_agency, only: [:create]
    before_action :find_agency, only: [:edit, :update]
    before_action :check_employer_staff_role, only: [:new]

    def new
      @agency= BenefitSponsors::Organizations::Forms::RegistrationForm.for_new(profile_type: profile_type)
      respond_to do |format|
        format.html
        format.js
      end
    end

    def create
      @agency= BenefitSponsors::Organizations::Forms::RegistrationForm.for_create(registration_params)
      begin
        # Alternate - use form object inside factory (or) do form.as_json inside service
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
    end

    def update
      @agency = BenefitSponsors::Organizations::Forms::RegistrationForm.for_update(profile_id: params[:id])
      sanitize_office_locations_params
      if can_update_profile?
        if @agency.update(organization_params)
          flash[:notice] = 'Employer successfully Updated.'
        else
          org_error_msg = @agency.errors.full_messages.join(",").humanize if @agency.errors.present?

          flash[:error] = "Employer information not saved. #{org_error_msg}."
        end
      else
        flash[:error] = 'You do not have permissions to update the details'
      end
      redirect_to sponsor_edit_registration_url
    end

    private

    def profile_type
      @profile_type = params[:profile_type] || params[:agency][:profile_type]
    end

    def initialize_agency
      # return if params[:agency].blank?
      # params[:agency].permit!
      # @agency= BenefitSponsors::Organizations::Forms::Profile.new(params[:agency])
    end

    def find_agency
      id = BSON::ObjectId.from_string(params[:id])
      @organization = BenefitSponsors::Organizations::Organization.where(:"profiles._id" => id).first
      if @organization.broker_agency_profile.present? && @organization.broker_agency_profile.id.to_s == id.to_s
        @broker_agency_profile = @organization.broker_agency_profile
      elsif @organization.employer_profile.present? && @organization.employer_profile.id.to_s == id.to_s
        @employer_profile = @organization.employer_profile
      end
      # id_params = params.permit(:id, :employer_profile_id)
      # id = id_params[:id] || id_params[:employer_profile_id]
      # @organization = BenefitSponsors::Organizations::Organization.where(:"profiles._id" => BSON::ObjectId.from_string(params[:id])).first
      # @employer_profile = @organization.employer_profile # TODO PICK correct Profile
      # render file: 'public/404.html', status: 404 if @employer_profile.blank?
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

    def sanitize_office_locations_params
      # TODO - implement in accepts_nested_attributes_for
      params["organization"].permit!
      params[:organization][:profiles_attributes].each do |key, profile|
        profile[:office_locations_attributes].each do |key, location|
          if location && location[:address_attributes]
            location[:is_primary] = (location[:address_attributes][:kind] == 'primary')
          end
        end
      end
    end

    def registration_params
      params[:agency].merge!({
        :current_user_id => current_user.id
      }) if is_employer_profile?
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
