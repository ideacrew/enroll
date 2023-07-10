# frozen_string_literal: true

module BenefitSponsors
  module Organizations
    # Policy for GeneralAgency
    class GeneralAgencyProfilePolicy < ApplicationPolicy
      def can_read_inbox?
        return false if user.blank?
        return true if user.has_hbx_staff_role? || user.has_general_agency_staff_role? || user.person.has_general_agency_staff_roles?
        false
      end

      def families?
        return false if user.blank?
        return true if user.has_hbx_staff_role?
        return false unless user.person

        staff_roles = user.person.general_agency_staff_roles.select(&:active?)
        staff_roles.any? do |sr|
          sr.benefit_sponsors_general_agency_profile_id == record.id
        end
      end
    end
  end
end
