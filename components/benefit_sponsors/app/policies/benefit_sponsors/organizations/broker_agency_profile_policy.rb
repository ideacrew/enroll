# frozen_string_literal: true

module BenefitSponsors
  module Organizations
    # policy for will BrokerAgencyProfile, inherits from main_app ApplicationPolicy
    class BrokerAgencyProfilePolicy < ::ApplicationPolicy

      # NOTE: All methods will most likely be consolidated with the auth refactor for BrokerAgencyProfilesController

      def redirect_signup?
        access_to_broker_agency_profile?
      end

      def access_to_broker_agency_profile?
        return false unless user
        return false unless user.person
        return true if user.person.hbx_staff_role
        return true if has_matching_broker_role?

        has_matching_broker_agency_staff_role?
      end

      def set_default_ga?
        access_to_broker_agency_profile?
      end

      def can_view_broker_agency?
        return true if hbx_staff_can_view_agency_staff?
        return true if has_matching_broker_role?
        return true if has_matching_broker_agency_staff_role?

        false
      end

      def can_manage_broker_agency?
        return true if hbx_staff_can_manage_agency_staff?
        return true if has_matching_broker_role?

        false
      end

      protected

      def has_matching_broker_agency_staff_role?
        staff_roles = user&.person&.broker_agency_staff_roles || []
        staff_roles&.any? do |sr|
          sr.active? &&
            (
              sr.broker_agency_profile_id == record.id ||
                sr.benefit_sponsors_broker_agency_profile_id == record.id
            )
        end
      end

      def has_matching_broker_role?
        broker_role = user&.person&.broker_role
        return false unless broker_role

        broker_role&.benefit_sponsors_broker_agency_profile_id == record.id && broker_role&.active?
      end

      ################################################################################################################
      # NOTE: the following methods or some variation thereof will hopefully appear in ApplicationPolicy
      # they will be deleted from this policy if present in the ApplicationPolicy of the main application
      ################################################################################################################

      def hbx_staff_can_view_agency_staff?
        permission&.view_agency_staff
      end

      def hbx_staff_can_manage_agency_staff?
        permission&.manage_agency_staff
      end
    end
  end
end

