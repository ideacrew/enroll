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
    end

    def assign
    end

    def messages
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
  end
end
