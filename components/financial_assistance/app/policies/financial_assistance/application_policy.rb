# frozen_string_literal: true

module FinancialAssistance
  # This class is base policy class
  # The ApplicationPolicy class is responsible for determining what actions a user can perform on Application records.
  # It checks if the user has the necessary permissions to perform actions on applications.
  # The permissions are determined based on the user's role and their relationship to the record.
  class ApplicationPolicy < Policy
    ACCESSABLE_ROLES = %w[hbx_staff_role broker_role active_broker_staff_roles].freeze

    def can_access_applications?
      return true if current_user == associated_user
      return true if role_has_permission_to_access_applications?
      false
    end

    private

    def role_has_permission_to_access_applications?
      role.present? && (current_user.has_hbx_staff_role? || can_broker_access?)
    end

    def can_broker_access?
      (role.is_a?(::BrokerRole) || role.is_a?(::BrokerAgencyStaffRole)) && broker_agency_profile_matches?
    end

    def broker_agency_profile_matches?
      associated_family.active_broker_agency_account.present? && associated_family.active_broker_agency_account.benefit_sponsors_broker_agency_profile_id == role.benefit_sponsors_broker_agency_profile_id
    end

    def role
      @role ||= find_role
    end

    def find_role
      person = user&.person
      return nil unless person

      ACCESSABLE_ROLES.detect do |role|
        return person.send(role) if person.respond_to?(role) && person.send(role)
      end

      nil
    end

    def current_user
      user
    end

    def associated_user
      associated_family_primary_member&.user
    end

    def associated_family_primary_member
      associated_family&.primary_person
    end

    def associated_family
      record&.family
    end
  end
end
