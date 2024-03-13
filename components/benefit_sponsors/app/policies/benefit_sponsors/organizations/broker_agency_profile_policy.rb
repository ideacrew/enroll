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
        return true if has_matching_broker_role?

        has_matching_broker_agency_staff_role?
      end

      def set_default_ga?
        access_to_broker_agency_profile?
      end

      def can_view_broker_agency?
        return true if admin_can_view_broker_agency?
        return true if is_broker_agency_primary?
        return true if is_broker_agency_broker?
        return true if is_broker_agency_staff?

        false
      end

      def can_manage_broker_agency?
        return true if admin_can_manage_broker_agency?
        return true if is_broker_agency_primary?

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
  
      def is_broker_agency_primary?
        return false unless broker_role
  
        broker_role.id == record&.primary_broker_role&.id
      end

      # For brokers who are not the primary broker, but still affiliated with the agency
      def is_broker_agency_broker?
        return false unless broker_role
  
        broker_role.benefit_sponsors_broker_agency_profile_id == record.id
      end
  
      def is_broker_agency_staff?
        staff_roles = account_holder_person&.active_broker_staff_roles || []
        return false if staff_roles.empty?
        id = record.id

        # Are any broker_agency_staff_roles still associated with a BrokerAgencyProfile, or have they all been migrated to BenefitSponsors::Organizations::BrokerAgencyProfile?
        staff_roles.detect{ |role| role&.broker_agency_profile&.id == id || role&.broker_agency_profile_id == id }
      end
    end
  end
end

