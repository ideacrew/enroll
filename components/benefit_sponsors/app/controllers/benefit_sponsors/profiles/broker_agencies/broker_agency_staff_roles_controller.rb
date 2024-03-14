# frozen_string_literal: true

module BenefitSponsors
  module Profiles
    module BrokerAgencies
      # controller that manages adding, approving and removing of staff agency roles to a broker
      class BrokerAgencyStaffRolesController < ::BenefitSponsors::ApplicationController
        before_action :find_and_authorize_broker_agency_profile, except: :search_broker_agency

        # search_broker_agency is a generic endpoint used to search across all agencies, only prereqs are being an admin or a broker/agent
        before_action :is_broker_or_admin?, only: :search_broker_agency

        def new
          @staff = BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.for_new
          set_ie_flash_by_announcement

          respond_to do |format|
            format.html { render 'new', layout: false} if params[:profile_type]
            format.js  { render 'new' }
          end
        end

        def create
          @staff = BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.for_create(broker_staff_params)
          begin
            @status,@result = @staff.save
            unless @staff.is_broker_registration_page
              flash[:notice] = "Role added successfully" if @status
              flash[:error] = "Role was not added because #{@result}" unless @status
            end
          rescue Exception => e
            flash[:error] = "Role was not added because #{e.message}"
          end
          respond_to do |format|
            format.html  { redirect_to profiles_broker_agencies_broker_agency_profile_path(id: params[:profile_id]) }
            format.js
          end
        end

        def approve
          @staff = BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.for_approve(broker_staff_params)
          authorize @staff
          begin
            @status, @result = @staff.approve
            if @status
              flash[:notice] = "Role approved successfully"
            else
              flash[:error] = "Role was not approved because #{@result}"
            end
          rescue Exception => e
            flash[:error] = "Role was not approved because #{e.message}"
          end
          redirect_to profiles_broker_agencies_broker_agency_profile_path(id: params[:profile_id])
        end

        def destroy
          @staff = BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.for_destroy(broker_staff_params)
          authorize @staff
          begin
            @status, @result = @staff.destroy
            if @status
              flash[:notice] = "Role removed successfully"
            else
              flash[:error] = "Role was not removed because #{@result}"
            end
          rescue Exception => e
            flash[:error] = "Role was not removed because #{e.message}"
          end
          redirect_to profiles_broker_agencies_broker_agency_profile_path(id: params[:profile_id])
        end

        def search_broker_agency
          @staff = BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.for_broker_agency_search(broker_staff_params)
          @broker_agency_profiles = @staff.broker_agency_search
        end

        private

        # NOTE: this will probably be consolidated with a similarily named method in BrokerAgencyProfilesController
        def find_and_authorize_broker_agency_profile
          # if profile_type is in the params with a value of 'broker_agency', this is actually an entirely different page
          # where a broker/agent (or aspiring broker/agent) can find agencies and send out an application
          # if not, profile_id must be present and this will render a small form on the broker homepage to add a new staff role to the broker
          return true if params[:profile_type] && params[:profile_type] == 'broker_agency'

          # the #new action is missing profile_id from broker_staff_params, hence this conditional
          profile_id = broker_staff_params[:profile_id] || params[:profile_id]
          organizations = BenefitSponsors::Organizations::Organization.where(:"profiles._id" => BSON::ObjectId(profile_id))

          broker_agency_profile = organizations&.first&.broker_agency_profile
          authorize broker_agency_profile, :can_manage_broker_agency?
        end

        def is_broker_or_admin?
          # agency profile record is not required for this auth method
          authorize BenefitSponsors::Organizations::BrokerAgencyProfile, :can_search_broker_agencies?
        end

        def broker_staff_params
          params[:staff].presence || params[:staff] = {}
          params[:staff].merge!({profile_id: params["staff"]["profile_id"] || params["profile_id"] || params["id"], person_id: params["person_id"], profile_type: params[:profile_type] || "broker_agency_staff",
                                 filter_criteria: params.permit(:q), is_broker_registration_page: params[:broker_registration_page] || params["staff"]["is_broker_registration_page"]})
          params[:staff].permit!
        end
      end
    end
  end
end
