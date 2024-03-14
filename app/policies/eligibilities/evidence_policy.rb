# frozen_string_literal: true

module Eligibilities
  # The EvidencePolicy class is responsible for determining what actions a user can perform on an Evidence record.
  # It checks if the user has the necessary permissions to upload, download, or destroy an Evidence record.
  # The permissions are determined based on the user's role and their relationship to the record.
  #
  # @example Checking if a user can upload an Evidence record
  #   policy = EvidencePolicy.new(user, record)
  #   policy.can_upload? #=> true
  class EvidencePolicy < ApplicationPolicy
    ACCESSABLE_ROLES = %w[hbx_staff_role broker_role active_broker_staff_roles].freeze

    def can_upload?
      allowed_to_modify?
    end

    def can_download?
      allowed_to_modify?
    end

    def can_destroy?
      allowed_to_modify?
    end

    private

    # Determines if the user is allowed to modify an Evidence record.
    # Access may be allowed to the roles: [HbxStaffRole, BrokerRole, BrokerStaffRole]
    #
    # @return [Boolean] Returns true if the user has the 'modify_family' permission or if the user is the primary person of the family associated with the record.
    #
    # @example Check if a user can modify an Evidence record
    #   allowed_to_modify? #=> true
    #
    # @note The user is the one who is trying to perform the action. The record_user is the user who owns the record. The record is an instance of Eligibilities::Evidence.
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

    def can_hbx_staff_modify?
      role.is_a?(HbxStaffRole) && role&.permission&.modify_family
    end

    def can_broker_modify?
      (has_active_broker_role? || has_active_broker_agency_staff_role?) && matches_individual_market_broker_account?
    end

    def broker_agency_profile_matches?
      associated_family.active_broker_agency_account.present? && associated_family.active_broker_agency_account.benefit_sponsors_broker_agency_profile_id == role.benefit_sponsors_broker_agency_profile_id
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
      role.any? { |r| r.is_a?(::BrokerAgencyStaffRole) }
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

    def associated_person
      associated_family.primary_person
    end

    def associated_user
      associated_person.user
    end

    def associated_family
      record.applicant.family
    end
  end
end