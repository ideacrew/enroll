module BenefitSponsors
    module Profiles
      module BrokerAgencies
        class BrokerAgencyStaffRolesController < ::BenefitSponsors::ApplicationController

          def new
            @staff = BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.for_new
            respond_to do |format|
              format.html
              format.js
            end
          end
          def create
           
          end
        end
      end
    end
end