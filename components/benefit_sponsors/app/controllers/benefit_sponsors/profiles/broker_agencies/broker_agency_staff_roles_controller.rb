module BenefitSponsors
    module Profiles
      module BrokerAgencies
        class BrokerAgencyStaffRolesController < ::BenefitSponsors::ApplicationController

          def new
            @staff = BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.for_new
            @staff.profile_type = "broker_agency"
            respond_to do |format|
              format.html
              format.js
            end
          end

          def create
            @staff = BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.for_create(broker_staff_params)
            authorize @staff
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

          def broker_staff_params
            params[:staff].present? ? params[:staff] :  params[:staff] = {}
            params[:staff].merge!({profile_id: params["profile_id"] || params["id"], person_id: params["person_id"], profile_type: "broker_agency"})
            params[:staff].permit!
          end

        end
      end
    end
end