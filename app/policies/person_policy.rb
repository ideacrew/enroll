# frozen_string_literal: true

# The PersonPolicy class defines the rules for which actions can be performed on a Person object.
# Each public method corresponds to a potential action that can be performed.
# The private methods are helper methods used to determine whether a user has the necessary permissions to perform an action.
class PersonPolicy < ApplicationPolicy
  ACCESSABLE_ROLES = %w[hbx_staff_role broker_role active_broker_staff_roles].freeze

  def can_show?
    allowed_to_modify?
  end

  def can_update?
    allowed_to_modify?
  end

  def updateable?
    return true unless role = user.person.hbx_staff_role
    role.permission.modify_family
  end

  def can_read_inbox?
    return true if user.person.hbx_staff_role
    true if user.person.broker_role || record.broker_role
  end

  def can_access_identity_verifications?
    return true if user.person.hbx_staff_role
    return true if user.person.id == record.id
    false
  end

  # This method checks if the current user have an HBX staff role, has the permission to modify the family.
  #
  # Example:
  #   can_hbx_staff_modify? # => true/false
  def can_hbx_staff_modify?
    has_hbx_staff_role? && role&.permission&.modify_family
  end

  # This method checks if the current user have a broker role, has the permission to modify either the individual account or the shop account.
  #
  # Example:
  #   can_broker_modify? # => true/false
  def can_broker_modify?
    has_broker_role? && (matches_individual_broker_account? || matches_shop_broker_account?)
  end

  private

  # Determines if the user is allowed to download the associated resource.
  # Access may be allowed to the roles: [HbxStaffRole, BrokerRole, BrokerAgencyStaffRole and EmployerStaffRole]
  #
  # @example Check if a user can modify an Evidence record
  #  allowed_to_download? # => true/false
  #
  # @note The user is the one who is trying to perform the action. The associated_user is the user who owns the record. The record is an instance of Person.
  def allowed_to_download?
    (current_user == associated_user) || role_has_permission_to_modify?
  end

  def allowed_to_modify?
    (current_user.person == record) || (current_user == associated_user) || role_has_permission_to_modify?
  end

  def associated_user
    associated_family&.primary_person&.user
  end

  def current_user
    user
  end

  def associated_family
    record.primary_family
  end

  def role_has_permission_to_modify?
    return false unless role.present?

    if has_hbx_staff_role?
      can_hbx_staff_modify?
    elsif has_broker_role?
      can_broker_modify?
    end
  end

  def matches_individual_broker_account?
    return false unless associated_family.active_broker_agency_account.present?
    matches_broker_agency_profile?(associated_family.active_broker_agency_account.benefit_sponsors_broker_agency_profile_id)
  end

  def matches_shop_broker_account?
    return false unless associated_employee_roles.present?
    associated_employee_roles.any? do |employee_role|
      matches_broker_agency_profile?(employee_role.employer_profile.active_broker_agency_account.benefit_sponsors_broker_agency_profile_id)
    end
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

  def associated_employee_roles
    record.active_employee_roles
  end

  def role
    @role ||= find_role
  end

  def has_broker_role?
    role.is_a?(::BrokerRole) || role.any? { |r| r.is_a?(::BrokerAgencyStaffRole) }
  end

  def has_hbx_staff_role?
    role.is_a?(::HbxStaffRole)
  end

  def find_role
    person = user&.person
    return nil unless person
    ACCESSABLE_ROLES.detect do |role|
      return person.send(role) if person.respond_to?(role) && person.send(role)
    end

    nil
  end

end