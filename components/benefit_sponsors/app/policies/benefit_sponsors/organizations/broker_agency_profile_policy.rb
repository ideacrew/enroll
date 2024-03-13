module BenefitSponsors
  module Organizations
    class BrokerAgencyProfilePolicy < ApplicationPolicy

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

      def can_search_broker_agencies?
        return true if admin_can_view_broker_agency?
        return true if has_broker_role_or_broker_agency_staff_role?

        false
      end

      def can_view_broker_agency?
        return true if admin_can_view_broker_agency?
        return true if is_broker_for_broker_agency?
        return true if is_staff_for_broker_agency?

        false
      end

      def can_manage_broker_agency?
        return true if admin_can_manage_broker_agency?
        return true if is_broker_for_broker_agency?

        false
      end

      protected

      def has_matching_broker_agency_staff_role?
        staff_roles = user.person.broker_agency_staff_roles || []
        staff_roles.any? do |sr|
          sr.active? &&
            (
              sr.broker_agency_profile_id == record.id ||
                sr.benefit_sponsors_broker_agency_profile_id == record.id
            )
        end
      end

      def has_matching_broker_role?
        broker_role = user.person.broker_role
        return false unless broker_role

        broker_role.benefit_sponsors_broker_agency_profile_id == record.id && broker_role.active?
      end

      def admin_can_view_broker_agency?
        return false unless hbx_staff_role_permission

        hbx_staff_role_permission.view_agency_staff
      end
  
      def admin_can_manage_broker_agency?
        return false unless hbx_staff_role_permission

        hbx_staff_role_permission.manage_agency_staff
      end

      # was originally using primary_broker method from broker_agency_profile to determine this auth step
      # but it is possible for some older profiles to have more than one broker
      def is_broker_for_broker_agency?
        return false unless broker_role
  
        broker_role&.broker_agency_profile&.id == record.id
      end
  
      def is_staff_for_broker_agency?
        return false unless broker_staff_roles && broker_staff_roles.present?

        broker_staff_roles.detect{ |role| role&.broker_agency_profile&.id == record.id || role&.broker_agency_profile_id == record.id }
      end

      def has_broker_role_or_broker_agency_staff_role?
        broker_role || (broker_staff_roles&.present?)
      end
    end
  end
end

