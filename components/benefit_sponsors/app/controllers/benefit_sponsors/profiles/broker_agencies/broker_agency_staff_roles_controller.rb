# frozen_string_literal: true

module BenefitSponsors
  module Profiles
    module BrokerAgencies
      # controller that manages adding, approving and removing of staff agency roles to a broker agency profile
      class BrokerAgencyStaffRolesController < ::BenefitSponsors::ApplicationController
        before_action :find_broker_agency_profile, only: [:new]

        def new
          # this endpoint is used for two scenarios
          # 1.) to render the form for brokers/agents creating new broker agency staff roles for their broker agencies
          # 2.) to render a different form in the view for benefit_sponsors/profiles/registrations/new for non-users sending in applications to be staff for existing broker agencies
          # authorization is only enforced here for the first scenario
          authorize @broker_agency_profile if request.format.js?

          @staff = BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.for_new
          set_ie_flash_by_announcement

          respond_to do |format|
            # the js template is for the first scenario metioned above^
            format.js  { render 'new' } if params[:profile_id]
            # the html template is for the second scenario metioned above^
            format.html { render 'new', layout: false} if params[:profile_type]
          end
        end

        # The endpoint is used to create applications to existing broker agencies and can be sent by anyone
        # This endpoint is unauthorized by design
        def create
          @staff = BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.for_create(broker_staff_params)

          begin
            @status,@result = @staff.save
            unless @staff.is_broker_registration_page
              flash[:notice] = "Staff member #{@staff.first_name} #{@staff.last_name} has been added." if @status
              flash[:warning] = "Role was not added because #{@result}" unless @status
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
              flash[:notice] = "Staff member #{@staff.first_name} #{@staff.last_name} has been approved."
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

        # This endpoint should remain unauthorized: it is used by BenefitSponsors::Profiles::RegistrationsController to search for Broker Agencies
        # By design, users do not have to be logged in to use this endpoint
        def search_broker_agency
          @staff = BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.for_broker_agency_search(broker_staff_params)
          @broker_agency_profiles = @staff.broker_agency_search
        end

        private

        def find_broker_agency_profile
          return unless params[:profile_id]
          profile_id = BSON::ObjectId(params[:profile_id])

          organizations = BenefitSponsors::Organizations::Organization.where(:"profiles._id" => profile_id)
          @broker_agency_profile = organizations&.first&.broker_agency_profile
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
