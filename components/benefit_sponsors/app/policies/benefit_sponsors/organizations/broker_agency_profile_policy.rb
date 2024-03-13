module BenefitSponsors
  module Organizations
    class BrokerAgencyProfilePolicy < ApplicationPolicy
      def redirect_signup?
        access_to_broker_agency_profile?
      end

      def access_to_broker_agency_profile?
        return false unless user
        return false unless user.person
        return true if user.person.hbx_staff_role
        return true if is_broker_agency_broker?

        is_broker_agency_staff?
      end

      def set_default_ga?
        access_to_broker_agency_profile?
      end

      def can_view_broker_agency?
        return true if admin_can_view_broker_agency?
        return true if is_broker_agency_broker?
        return true if is_broker_agency_staff?

        false
      end

      def can_manage_broker_agency?
        binding.irb
        return true if admin_can_manage_broker_agency?
        return true if is_broker_agency_broker?

        false
      end

      protected

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
      def is_broker_agency_broker?
        return false unless broker_role
  
        broker_role&.broker_agency_profile&.id == record.id
      end
  
      def is_broker_agency_staff?
        staff_roles = account_holder_person&.active_broker_staff_roles || []
        return false if staff_roles.empty?

        staff_roles.detect{ |role| role&.broker_agency_profile&.id == record.id || role&.broker_agency_profile_id == record.id }
      end
    end
  end
end

