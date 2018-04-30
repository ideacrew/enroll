module BenefitSponsors
  module Profiles
    class BrokerAgencies::BrokerAgencyProfilesController < ApplicationController
      include Acapi::Notifiers
      include DataTablesAdapter
      include Concerns::ProfileRegistration

      rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

      # before_action :find_broker_agency_profile, only: [:employers, :assign, :update_assign, :employer_datatable, :manage_employers, :general_agency_index, :clear_assign_for_employer, :set_default_ga, :assign_history]
      before_action :set_current_person, only: [:staff_index, :broker_portal]
      # before_action :check_general_agency_profile_permissions_assign, only: [:assign, :update_assign, :clear_assign_for_employer, :assign_history]
      # before_action :check_general_agency_profile_permissions_set_default, only: [:set_default_ga]

      layout 'single_column'

      EMPLOYER_DT_COLUMN_TO_FIELD_MAP = {
        "2"     => "legal_name",
        "4"     => "employer_profile.aasm_state",
        "5"     => "employer_profile.plan_years.start_on"
      }

      def index
        authorize self
        @broker_agency_profiles = BenefitSponsors::Organizations::Organization.broker_agency_profiles.map(&:broker_agency_profile)
      end

      def show
        set_flash_by_announcement
        @broker_agency_profile = ::BenefitSponsors::Organizations::BrokerAgencyProfile.find(params[:id])
        @provider = current_user.person
      end

      def staff_index
      end

      def family_datatable
        authorize self
        find_broker_agency_profile(BSON::ObjectId.from_string(params.permit(:id)[:id]))
        dt_query = extract_datatable_parameters

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
        authorize self
        find_broker_agency_profile(BSON::ObjectId.from_string(params.permit(:id)[:id]))
        @q = params.permit(:q)[:q]

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
        @sent_box = true
        @provider = current_user.person
        respond_to do |format|
          format.js {}
        end
      end


      def agency_messages
      end

      def inbox
        @sent_box = true
        id = params["id"]||params['profile_id']
        @broker_agency_provider = find_broker_agency_profile(BSON::ObjectId(id))
        @folder = (params[:folder] || 'Inbox').capitalize
        if current_user.person._id.to_s == id
          @provider = current_user.person
        else
          @provider = @broker_agency_provider
        end
      end

      # def redirect_to_show(broker_agency_profile_id)
      #   redirect_to profiles_broker_agencies_broker_agency_profile_path(id: broker_agency_profile_id)
      # end

      private

      def find_broker_agency_profile(broker_agency_profile_id = nil)
        id = broker_agency_profile_id || BSON::ObjectId(params[:id])
        organizations = BenefitSponsors::Organizations::Organization.where(:"profiles._id" => id)
        @broker_agency_profile = organizations.first.broker_agency_profile if organizations.present?
        authorize @broker_agency_profile, :access_to_broker_agency_profile?
      end

      def user_not_authorized(exception)
        if current_user.has_broker_agency_staff_role?
          redirect_to profiles_broker_agencies_broker_agency_profile_path(:id => current_user.person.broker_agency_staff_roles.first.broker_agency_profile_id)
        else
          redirect_to benefit_sponsors.new_profiles_registration_path(:profile_type => :broker_agency)
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
