module BenefitSponsors
  module Profiles
    module BrokerAgencies
      class BrokerAgencyStaffRolesController < ::BenefitSponsors::ApplicationController

        def new
          @staff = BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.for_new
          respond_to do |format|
            format.html { render 'new', layout: false}
          end
        end

        def new_staff_form
          @staff = BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.for_new
          @staff.profile_type = "broker_agency_staff"
          respond_to do |format|
            format.html
            format.js
          end
        end

        def create
          @staff = BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.for_create(broker_staff_params)
          @status , @result = @staff.save
          unless @status
            @messages = (' Broker Staff Role was not added because '  + @result)
          else
            @messages = "Broker Staff Role added"
          end
          respond_to do |format|
            format.js
          end
        end

        def create_broker_staff
          @staff = BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.for_create(broker_staff_params)
          authorize @staff
          begin
            @status , @result = @staff.save
            if @status
              flash[:notice] = "Role added sucessfully"
            else
              flash[:error] = "Role was not added because " + @result
            end
          rescue Exception => e
            flash[:error] = "Role was not added because " + e.message
          end
          redirect_to profiles_broker_agencies_broker_agency_profile_path(id:params[:profile_id])
        end

        def approve
          @staff = BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.for_approve(broker_staff_params)
          authorize @staff
          begin
            @status, @result = @staff.approve
            if @status
              flash[:notice] = "Role approved sucessfully"
            else
              flash[:error] = "Role was not approved because " + @result
            end
          rescue Exception => e
            flash[:error] = "Role was not approved because " + e.message
          end
          redirect_to profiles_broker_agencies_broker_agency_profile_path(id:params[:profile_id])
        end

        def destroy
          @staff = BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.for_destroy(broker_staff_params)
          authorize @staff
          begin
            @status, @result = @staff.destroy
            if @status
              flash[:notice] = "Role removed succesfully"
            else
              flash[:error] = "Role was not removed because " + @result
            end
          rescue Exception => e
            flash[:error] = "Role was not removed because " + e.message
          end
          redirect_to profiles_broker_agencies_broker_agency_profile_path(id:params[:profile_id])
        end

        def search_broker_agency
          @broker_agencies = BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.for_broker_agency_search(broker_staff_params)
          @broker_agency_profiles =  @broker_agencies.broker_agency_search
        end

        private

        def broker_staff_params
          params[:staff].present? ? params[:staff] :  params[:staff] = {}
          params[:staff].merge!({profile_id: params["staff"]["profile_id"] || params["profile_id"] || params["id"], person_id: params["person_id"], profile_type:  params[:profile_type] || "broker_agency_staff",
                                  filter_criteria: params.permit(:q), is_broker_registration_page: params[:broker_registration_page]})
          params[:staff].permit!
        end
      end
    end
  end
end
