module BenefitSponsors
  module Organizations
    class GeneralAgencyProfilePolicy < ApplicationPolicy
      def can_read_inbox?
        return false if user.blank?
        return true if user.has_hbx_staff_role? || user.has_general_agency_staff_role?
        false
      end
    end
  end
end
