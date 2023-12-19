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
    end
  end
end

