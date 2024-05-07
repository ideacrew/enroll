# frozen_string_literal: true

module BenefitSponsors
  module Organizations
    # Policy for GeneralAgency
    class GeneralAgencyProfilePolicy < ApplicationPolicy
      def show?
        return false if user.blank?
        return true if user.has_hbx_staff_role?
        return true if user.has_general_agency_staff_role? && user_has_benefit_sponsors_ga_profile?
        return true if user.has_general_agency_staff_role? && user_has_ga_profile?
        false
      end

      def employers?
        families?
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

      def can_read_inbox?
        show?
      end

      def can_download_document?
        show?
      end

      def user_has_benefit_sponsors_ga_profile?
        ga_staff_roles = user.person&.general_agency_staff_roles
        ga_staff_roles&.pluck(:benefit_sponsors_general_agency_profile_id)&.include?(record.id)
      end

      def user_has_ga_profile?
        ga_staff_roles = user.person&.general_agency_staff_roles
        ga_staff_roles&.pluck(:general_agency_profile_id)&.include?(record.id)
      end

    end
  end
end
