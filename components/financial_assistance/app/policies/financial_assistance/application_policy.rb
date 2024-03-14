# frozen_string_literal: true

module FinancialAssistance
  # This class is base policy class
  # The ApplicationPolicy class is responsible for determining what actions a user can perform on Application records.
  # It checks if the user has the necessary permissions to perform actions on applications.
  # The permissions are determined based on the user's role and their relationship to the record.
  class ApplicationPolicy < Policy
    ACCESSABLE_ROLES = %w[hbx_staff_role broker_role active_broker_staff_roles consumer_role].freeze

    def can_view_checklist_pdf?
      allowed_to_view?
    end

    def can_access_application?
      allowed_to_modify?
    end

    def can_review?
      allowed_to_modify?
    end

    private

    def allowed_to_view?
      role.present?
    end

    def allowed_to_modify?
      return true if current_user == associated_user
      return true if role_has_permission_to_access_applications?
      false
    end

    def allowed_to_modify?
      return false unless individual_market_role_identity_verified?
      return true if (current_user == associated_user)
      return false unless role.present?
      return can_hbx_staff_modify? if role.is_a?(HbxStaffRole)
      return can_broker_modify? if (has_active_broker_role? || has_active_broker_agency_staff_role?)
      false
    end

    def individual_market_role_identity_verified?
      return true if (associated_person.resident_role || associated_person.consumer_role&.identity_verified?)
      false
    end

    def role_has_permission_to_access_applications?
      role.present? && (can_hbx_staff_modify? || can_broker_access?)
    end

        # Checks if the broker agency profile ID of any of the roles
    # matches the provided broker agency profile ID.
    #
    # @note The `role` can be a single broker role or multiple active broker agency staff roles.
    #
    # @param active_broker_agency_profile_id [String] The broker agency profile ID to match against.
    #
    # @return [Boolean] returns true if there is a match, false otherwise.
    def matches_broker_agency_profile?(active_broker_agency_profile_id)
      Array(role).any? do |role|
        role.benefit_sponsors_broker_agency_profile_id == active_broker_agency_profile_id
      end
    end

    def matches_individual_market_broker_account?
      return false unless associated_family.active_broker_agency_account.present?
      matches_broker_agency_profile?(associated_family.active_broker_agency_account.benefit_sponsors_broker_agency_profile_id)
    end

    def has_active_broker_role?
      role.is_a?(::BrokerRole) && role.active?
    end

    def has_active_broker_agency_staff_role?
      Array(role).any? { |r| r.is_a?(::BrokerAgencyStaffRole) }
    end


    def can_hbx_staff_modify?
      role.is_a?(HbxStaffRole) && role&.permission&.modify_family
    end

    def can_broker_modify?
      (has_active_broker_role? || has_active_broker_agency_staff_role?) && matches_individual_market_broker_account?
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
      associated_person.user
    end

    def associated_person
      associated_family&.primary_person
    end

    def associated_family
      record&.family
    end
  end
end
