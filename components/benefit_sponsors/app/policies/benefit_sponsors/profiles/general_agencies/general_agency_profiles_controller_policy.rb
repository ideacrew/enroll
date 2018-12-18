module BenefitSponsors
  module Profiles
    module GeneralAgencies
      class GeneralAgencyProfilesControllerPolicy < ApplicationPolicy

        def family_index?
          return user.has_hbx_staff_role? || user.has_general_agency_staff_role?
        end

        # def family_datatable?
        #   family_index?
        # end

        # def index?
        #   return user.has_hbx_staff_role? || user.has_csr_role?
        # end

        def show?
          return user.has_hbx_staff_role? || user.has_general_agency_staff_role?
        end

        def edit_staff
          return user.has_hbx_staff_role? || user.has_general_agency_staff_role?
        end

        def update_staff
          return user.has_hbx_staff_role? || user.has_general_agency_staff_role?
        end

        def staffs
          return user.has_hbx_staff_role? || user.has_general_agency_staff_role?
        end

        def redirect_signup?
          user.present?
        end

        def staff_index?
          return user.has_hbx_staff_role? || user.has_general_agency_staff_role?
        end
      end
    end
  end
end
