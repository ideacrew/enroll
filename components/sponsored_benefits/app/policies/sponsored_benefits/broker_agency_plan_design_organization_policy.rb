# frozen_string_literal: true

module SponsoredBenefits
  # Determines access rights for working with broker agency quotes.
  class BrokerAgencyPlanDesignOrganizationPolicy < Policy
    def manage_quotes?
      return false unless user
      return true if user.has_hbx_staff_role?
      return false unless user.person

      broker_agency_staff_roles = user.person.broker_agency_staff_roles.select(&:is_active?)

      allowed_as_staff = broker_agency_staff_roles.any? do |basr|
        basr.benefit_sponsors_broker_agency_profile_id == record.id
      end

      return true if allowed_as_staff

      broker_role = user.person.broker_role
      return false unless broker_role
      return false unless broker_role.active?

      broker_role.benefit_sponsors_broker_agency_profile_id == record.id
    end
  end
end