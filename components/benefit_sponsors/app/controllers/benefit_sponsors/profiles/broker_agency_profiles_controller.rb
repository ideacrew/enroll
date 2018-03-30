module BenefitSponsors
  class Profiles::BrokerAgencyProfilesController < ApplicationController
    include Acapi::Notifiers
    include DataTablesAdapter

    before_action :check_broker_agency_staff_role, only: [:new, :create]
    before_action :check_admin_staff_role, only: [:index]
    before_action :find_hbx_profile, only: [:index]
    before_action :find_broker_agency_profile, only: [:show, :edit, :update, :employers, :assign, :update_assign, :employer_datatable, :manage_employers, :general_agency_index, :clear_assign_for_employer, :set_default_ga, :assign_history]
    before_action :set_current_person, only: [:staff_index, :new]
    before_action :check_general_agency_profile_permissions_assign, only: [:assign, :update_assign, :clear_assign_for_employer, :assign_history]
    before_action :check_general_agency_profile_permissions_set_default, only: [:set_default_ga]

    layout 'single_column'

    EMPLOYER_DT_COLUMN_TO_FIELD_MAP = {
      "2"     => "legal_name",
      "4"     => "employer_profile.aasm_state",
      "5"     => "employer_profile.plan_years.start_on"
    }

    def index
    end

    def new
      @profile = Organizations::BrokerAgencyProfile.new
      @organization = BenefitSponsors::Organizations::Factories::BrokerProfileFactory.new(@profile, nil)
    end

    def create
    end

    def show
      set_flash_by_announcement
      session[:person_id] = nil
       @provider = current_user.person
       @staff_role = current_user.has_broker_agency_staff_role?
       @id=params[:id]
    end

    def edit
      @form_broker_agency_profile = BenefitSponsors::Organizations::Factories::BrokerProfileFactory.find(@broker_agency_profile.id)
      @id = params[:id]
    end

    def update
      authorize HbxProfile, :modify_admin_tabs?
      sanitize_broker_profile_params
      params.permit!

      # lookup by the origanization and not BrokerAgencyProfile
      @organization = BenefitSponsors::Organizations::Organization.find(params[:organization][:id])
      @organization_dup = @organization.office_locations.as_json

      #clear office_locations, don't worry, we will recreate
      @organization.assign_attributes(:office_locations => [])
      @organization.save(validate: false)
      person = @broker_agency_profile.primary_broker_role.person
      person.update_attributes(person_profile_params)
      @broker_agency_profile.update_attributes(languages_spoken_params)

      if @organization.update_attributes(broker_profile_params)
        office_location = @organization.primary_office_location
        if office_location.present? && office_location.phone.present?
          update_broker_phone(office_location, person)
        end

        flash[:notice] = "Successfully Update Broker Agency Profile"
        redirect_to profiles_broker_agency_profile_path(@broker_agency_profile)
      else

        @organization.assign_attributes(:office_locations => @organization_dup)
        @organization.save(validate: false)

        flash[:error] = "Failed to Update Broker Agency Profile"
        #render "edit"
        redirect_to profiles_broker_agency_profile_path(@broker_agency_profile)
      end
    end

    def assign
    end

    def messages
    end

    private

    def broker_profile_params
      params.require(:organization).permit(
        :legal_name,
        :dba,
        :home_page,
        :office_locations_attributes => [
          :address_attributes => [:kind, :address_1, :address_2, :city, :state, :zip],
          :phone_attributes => [:kind, :area_code, :number, :extension],
          :email_attributes => [:kind, :address]
        ]
      )
    end

    def languages_spoken_params
      params.require(:organization).permit(
        :languages_spoken => []
      )
    end

    def person_profile_params
      params.require(:organization).permit(:first_name, :last_name, :dob)
    end

    def sanitize_broker_profile_params
      params[:organization][:office_locations_attributes].each do |key, location|
        params[:organization][:office_locations_attributes].delete(key) unless location['address_attributes']
        location.delete('phone_attributes') if (location['phone_attributes'].present? && location['phone_attributes']['number'].blank?)
      end
    end

    def find_broker_agency_profile
      @broker_agency_profile = BenefitSponsors::Organizations::Organization.where(:"profiles._id" => BSON::ObjectId(params[:id])).first.broker_agency_profile
      # authorize @broker_agency_profile, :access_to_broker_agency_profile?
    end

    def check_broker_agency_staff_role
      if current_user.has_broker_agency_staff_role?
        redirect_to profiles_broker_agency_profile_path(:id => current_user.person.broker_agency_staff_roles.first.broker_agency_profile_id)
      elsif current_user.has_broker_role?
        redirect_to profiles_broker_agency_profile_path(id: current_user.person.broker_role.broker_agency_profile_id.to_s)
      else
        flash[:notice] = "You don't have a Broker Agency Profile associated with your Account!! Please register your Broker Agency first."
      end
    end

    def update_broker_phone(office_location, person)
      phone = office_location.phone
      broker_main_phone = person.phones.where(kind: "phone main").first
      if broker_main_phone.present?
        broker_main_phone.update_attributes!(
          kind: phone.kind,
          country_code: phone.country_code,
          area_code: phone.area_code,
          number: phone.number,
          extension: phone.extension,
          full_phone_number: phone.full_phone_number
        )
      end
      person.save!
    end

  end
end
