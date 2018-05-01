module BenefitSponsors
  module Profiles
    module BrokerAgencies
      class BrokerAgencyProfilesControllerPolicy < ApplicationPolicy

        def family_index?
          return user.has_hbx_staff_role? || user.has_broker_role?
        end

        def family_datatable?
          return user.has_hbx_staff_role? || user.has_broker_role?
        end

        def index?
          return user.has_hbx_staff_role? || user.has_csr_role?
        end
      end
    end
  end
end
