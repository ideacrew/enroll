# frozen_string_literal: true

module SponsoredBenefits
  # Policy for General Agency and Broker Agency Plan Design Organization
  class PlanDesignOrganizationPolicy < Policy
    def can_access_employers_tab_via_ga_portal?
      return false unless user
      return true if user.has_hbx_staff_role?
      return false if record.blank?
      return false unless user.person

      general_agency_staff_roles = user.person.active_general_agency_staff_roles
      general_agency_staff_roles.any? do |gasr|
        gasr.benefit_sponsors_general_agency_profile_id == record.id
      end
    end

    def view_proposals?
      return true if user.has_hbx_staff_role?
      return false unless user.person
      person = user.person

      return true if broker_owns_plan_design_organization_via_broker_agency?(person)
      return true if broker_staff_owns_plan_design_organization_via_broker_agency?(person)

      general_agency_staff_roles = person.active_general_agency_staff_roles
      general_agency_staff_roles.any? do |gasr|
        ga_profile_id = gasr.benefit_sponsors_general_agency_profile_id
        record.general_agency_accounts.active.any? do |gaa|
          # Not a typo - that *is* the source column name
          gaa.benefit_sponsrship_general_agency_profile_id == ga_profile_id
        end
      end
    end

    def view_employees?
      view_proposals?
    end

    private

    def broker_staff_owns_plan_design_organization_via_broker_agency?(person)
      broker_agency_staff_roles = person.active_broker_staff_roles
      return false if broker_agency_staff_roles.blank?

      broker_agency_staff_roles.any? do |basr|
        basr.benefit_sponsors_broker_agency_profile_id == record.owner_profile_id
      end
    end

    def broker_owns_plan_design_organization_via_broker_agency?(person)
      return false unless person.broker_role&.active?

      person.broker_role.benefit_sponsors_broker_agency_profile_id == record.owner_profile_id
    end
  end
end
