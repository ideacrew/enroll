# frozen_string_literal: true

module SponsoredBenefits
  # Policy for General Agency and Broker Agency Plan Design Organization
  class PlanDesignOrganizationPolicy < Policy

    def can_access_employers_tab_via_ga_portal?
      return false unless user
      return true if user.has_hbx_staff_role?
      return false if record.blank?

      user_has_ga_staff_role? && ga_staff_belongs_to_agency?
    end

    def has_role?(role_sym)
      return false if person_id.blank?
      roles.any? { |r| r == role_sym.to_s }
    end

    def user_has_ga_staff_role?
      return false unless user.has_role?("general_agency_staff")

      user.has_general_agency_staff_role?
    end

    def ga_staff_belongs_to_agency?
      user.person.active_general_agency_staff_roles.any? {|role| role.benefit_sponsors_general_agency_profile_id.to_s == record.id.to_s }
    end
  end
end
