# frozen_string_literal: true

class PersonPolicy < ApplicationPolicy
  ACCESSABLE_ROLES = %w[hbx_staff_role broker_role active_broker_staff_roles].freeze

  def can_show?
    allowed_to_modify?
  end

  def can_update?
    allowed_to_modify?
  end

  def can_download_document?
    allowed_to_download?
  end

  def can_delete_document?
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

  def can_hbx_staff_modify?
    role.is_a?(HbxStaffRole) && role&.permission&.modify_family
  end

  private

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
    role.present? && (can_hbx_staff_modify? || can_broker_modify?)
  end

  def can_broker_modify?
    (role.is_a?(::BrokerRole) || role.any? { |r| r.is_a?(::BrokerAgencyStaffRole) }) && (matches_individual_broker_account? || matches_shop_broker_account?)
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

  def find_role
    person = user&.person
    return nil unless person
    ACCESSABLE_ROLES.detect do |role|
      return person.send(role) if person.respond_to?(role) && person.send(role)
    end

    nil
  end

end
