module BenefitSponsors
  module Profiles
    module BrokerAgencies
      class BrokerAgencyStaffRolesController < ::BenefitSponsors::ApplicationController

        def new
          @staff = BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.for_new
          respond_to do |format|
            format.html { render 'new', layout: false}
            format.js
          end
        end

        def create
          @staff = BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.for_create(staff_params)
            @status , @result = @staff.save
          unless @status
            @messages = (' Broker Staff Role was not added because '  + @result)
          else
            @messages = "Broker Staff Role added sucessfully"
          end
          respond_to do |format|
            format.js
          end
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
          params[:staff].merge!({profile_id: params["profile_id"] || params["id"], person_id: params["person_id"], profile_type: "broker_agency_staff"})
          params[:staff].permit!
        end
      end
    end
  end
end
