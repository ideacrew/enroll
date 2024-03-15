# frozen_string_literal: true

module BenefitSponsors
  module Organizations
    # NOTE: for now this class is inheriting from BenefitSponsors::ApplicationPolicy, due to not being able to pass the GHAs
    # Once the GHA workflow has been updated, this will inherit from the main app ApplicationPolicy
    class BrokerAgencyProfilePolicy < BenefitSponsors::ApplicationPolicy

      # NOTE: this method is only used by the BrokerAgencyProfileStaffRolesController
      def new?
        access_to_broker_agency_profile?
      end

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
        staff_roles = account_holder_person&.broker_agency_staff_roles || []
        staff_roles&.any? do |sr|
          sr.active? &&
            (
              sr.broker_agency_profile_id == record.id ||
                sr.benefit_sponsors_broker_agency_profile_id == record.id
            )
        end
      end

      def has_matching_broker_role?
        broker_role = account_holder_person.broker_role
        return false unless broker_role

        broker_role&.benefit_sponsors_broker_agency_profile_id == record.id && broker_role&.active?
      end
    end
  end
end

