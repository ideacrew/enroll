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
          begin
            @status , @result = @staff.save
            unless @status
              flash[:error] = (' Broker Staff Role was not added because '  + @result)
            else
              flash[:notice] = "Broker Staff Role added sucessfully"
            end
          rescue Exception => e
            flash[:error] = e.message
          end
          redirect_to new_profiles_registration_path(profile_type: "broker_agency")
        end

        def create_broker_staff
          @staff = BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.for_create(broker_staff_params)
          begin
            @status , @result = @staff.save
            if @status
              flash[:notice] = "Role added sucessfully"
            else
              flash[:error] = "Role not added due to " + @result
            end
          rescue Exception => e
            flash[:error] = "Role not added due to " + e.message
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
              flash[:error] = "Role not approved due to " + @result
            end
          rescue Exception => e
            flash[:error] = "Role not approved due to " + e.message
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
              flash[:error] = "Role not removed due to " + @result
            end
          rescue Exception => e
            flash[:error] = "Role not removed due to " + e.message
          end
          redirect_to profiles_broker_agencies_broker_agency_profile_path(id:params[:profile_id])
        end

        def search_broker_agency
          @filter_criteria = params.permit(:q)
          results = BenefitSponsors::Organizations::Organization.broker_agencies_with_matching_agency_or_broker(@filter_criteria, params[:broker_registration_page])
          if results.first.is_a?(Person)
            @filtered_broker_roles  = results.map(&:broker_role)
            @broker_agency_profiles = results.map{|broker| broker.broker_role.broker_agency_profile}.uniq
          else
            @broker_agency_profiles = results.map(&:broker_agency_profile).uniq
          end
        end

        private

        def broker_staff_params
          params[:staff].present? ? params[:staff] :  params[:staff] = {}
          params[:staff].merge!({profile_id: params["staff"]["profile_id"] || params["profile_id"] || params["id"], person_id: params["person_id"], profile_type:  params[:profile_type] || "broker_agency_staff"})
          params[:staff].permit!
        end
      end
    end
  end
end
