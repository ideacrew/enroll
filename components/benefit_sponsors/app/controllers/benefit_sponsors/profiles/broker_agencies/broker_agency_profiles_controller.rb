module BenefitSponsors
  module Profiles
    class BrokerAgencies::BrokerAgencyProfilesController < ApplicationController
      include Acapi::Notifiers
      include DataTablesAdapter
      include Concerns::ProfileRegistration

      # before_action :check_broker_agency_staff_role, only: [:broker_portal]
      before_action :check_admin_staff_role, only: [:index]
      before_action :find_hbx_profile, only: [:index]
      # before_action :find_broker_agency_profile, only: [:show, :edit, :update, :employers, :assign, :update_assign, :employer_datatable, :manage_employers, :general_agency_index, :clear_assign_for_employer, :set_default_ga, :assign_history]
      before_action :set_current_person, only: [:staff_index, :broker_portal]
      before_action :check_general_agency_profile_permissions_assign, only: [:assign, :update_assign, :clear_assign_for_employer, :assign_history]
      before_action :check_general_agency_profile_permissions_set_default, only: [:set_default_ga]

      layout 'single_column'

      EMPLOYER_DT_COLUMN_TO_FIELD_MAP = {
        "2"     => "legal_name",
        "4"     => "employer_profile.aasm_state",
        "5"     => "employer_profile.plan_years.start_on"
      }

      def index
        @broker_agency_profiles = BenefitSponsors::Organizations::Organization.broker_agency_profiles.map(&:broker_agency_profile)
      end

      def broker_portal
        result, @profile_id = BenefitSponsors::Organizations::Forms::RegistrationForm.for_broker_portal(current_user)

        if result
          redirect_to broker_show_registration_url(@profile_id)
        else
          flash[:notice] = "You don't have a Broker Agency Profile associated with your Account!! Please register your Broker Agency first."
        end
      end

      def show
        set_flash_by_announcement
        @broker_agency_profile = ::BenefitSponsors::Organizations::BrokerAgencyProfile.find(params[:id])
      end

      def staff_index
      end

      def family_datatable
        id = params[:id]
        is_search = false
        dt_query = extract_datatable_parameters

        if current_user.has_broker_role?
          find_broker_agency_profile(current_user.person.broker_role.broker_agency_profile_id)
        elsif current_user.has_hbx_staff_role?
          find_broker_agency_profile(BSON::ObjectId.from_string(id))
        else
          redirect_to broker_portal_profiles_broker_agencies_broker_agency_profiles_path
          return
        end

        query = BenefitSponsors::Queries::BrokerFamiliesQuery.new(dt_query.search_string, @broker_agency_profile.id)
        @total_records = query.total_count
        @records_filtered = query.filtered_count
        @families = query.filtered_scope.skip(dt_query.skip).limit(dt_query.take).to_a
        primary_member_ids = @families.map do |fam|
          fam.primary_family_member.person_id
        end
        @primary_member_cache = {}
        Person.where(:_id => { "$in" => primary_member_ids }).each do |pers|
          @primary_member_cache[pers.id] = pers
        end

        @draw = dt_query.draw
      end

      def family_index
        @q = params.permit(:q)[:q]

        if current_user.has_broker_role?
          find_broker_agency_profile(current_user.person.broker_role.broker_agency_profile_id)
        elsif current_user.has_hbx_staff_role?
          find_broker_agency_profile(BSON::ObjectId.from_string(params.permit(:id)[:id]))
        else
          redirect_to broker_portal_profiles_broker_agencies_broker_agency_profiles_path
          return
        end

        respond_to do |format|
          format.js {}
        end
      end

      def employers
      end

      #TODO Implement when we move GeneralAgencyProfile in Engine.
      def general_agency_index
      end

      def set_default_ga
      end

      def employer_datatable
      end

      def assign
      end

      def update_assign
      end

      def clear_assign_for_employer
      end

      def assign_history
      end

      def manage_employers
      end

      def messages
      end

      def agency_messages
      end

      def inbox
      end

      def redirect_to_show(broker_agency_profile_id)
        redirect_to profiles_broker_agencies_broker_agency_profile_path(id: broker_agency_profile_id)
      end

      private

      def find_hbx_profile
        @profile = current_user.person.hbx_staff_role.hbx_profile
      end

      def find_broker_agency_profile(broker_agency_profile_id = nil)
        id = broker_agency_profile_id || BSON::ObjectId(params[:id])
        @broker_agency_profile = BenefitSponsors::Organizations::Organization.where(:"profiles._id" => id).first.broker_agency_profile
        # authorize @broker_agency_profile, :access_to_broker_agency_profile?
      end

      def check_admin_staff_role
        if current_user.has_hbx_staff_role? || current_user.has_csr_role?
        elsif current_user.has_broker_agency_staff_role?
          redirect_to profiles_broker_agencies_broker_agency_profile_path(:id => current_user.person.broker_agency_staff_roles.first.broker_agency_profile_id)
        else
          redirect_to broker_portal_profiles_broker_agencies_broker_agency_profiles_path
        end
      end

      def check_broker_agency_staff_role
        if current_user.has_broker_agency_staff_role?
          redirect_to profiles_broker_agencies_broker_agency_profile_path(:id => current_user.person.broker_agency_staff_roles.first.broker_agency_profile_id)
        elsif current_user.has_broker_role?
          redirect_to profiles_broker_agencies_broker_agency_profile_path(id: current_user.person.broker_role.broker_agency_profile_id.to_s)
        else
          flash[:notice] = "You don't have a Broker Agency Profile associated with your Account!! Please register your Broker Agency first."
        end
      end

      def send_general_agency_assign_msg(general_agency, employer_profile, status)
      end

      def eligible_brokers
      end

      def update_ga_for_employers(broker_agency_profile, old_default_ga=nil)
      end

      def person_market_kind
      end

      def check_general_agency_profile_permissions_assign
      end

      def check_general_agency_profile_permissions_set_default
      end
    end
  end
end
