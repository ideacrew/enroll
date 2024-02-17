# frozen_string_literal: true

# The FamilyMemberPolicy class is responsible for determining what actions a user can perform when modifying their family
# on either a QLE or SEP-related page
# These permissions do NOT apply to the family tab accessed by users during registration or under the 'Manage Family' sidebar

# This class will check if the user has the necessary permissions to view, add, update, or modify a FamilyMember record.
# The permissions are determined based on the user's role and their relationship to the record.
#
# @example Checking if a user can update a FamilyMember record
#   policy = FamilyMemberPolicy.new(user, record)
#   policy.can_modify_family_members? #=> true, OR
#   authorize family_member, :method_name #=> true
class FamilyMemberPolicy < ApplicationPolicy
  ACCESSABLE_ROLES = %w[hbx_staff_role broker_role active_broker_staff_roles].freeze

  # NOTE: while 'can_modify_family_members?' is the name of this method, it also applies to the `show` and `edit`, `new`, and `index` methods of the `insured/family_members_controller`
  # as well as the `create`, `update`, and `destroy` methods
  # We're only using this one method now -- more can be made as the need to separate permissions for different CRUD operations arises
  def can_modify_family_members?
    allowed_to_modify?
  end

  private

  # Determines if the user is allowed to perform CRUD operations on a FamilyMember record
  #
  # @return [Boolean] Returns true if the user has the 'modify_family' permission or if the user is the primary person of the family associated with the record.
  #
  # @example Check if a user can modify a FamilyMember record
  #   allowed_to_modify? #=> true
  #
  # @note The user is the one who is trying to perform the action. The record_user is the user who owns the record. The record is an instance of FamilyMember.
  def allowed_to_modify?
    (current_user == associated_user) || role_has_permission_to_modify_family_members?
  end

  def role_has_permission_to_modify_family_members?
    role.present? && (can_hbx_staff_modify? || can_broker_modify?)
  end

  def can_hbx_staff_modify?
    role.is_a?(HbxStaffRole) && role&.permission&.modify_family
  end

  def can_broker_modify?
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