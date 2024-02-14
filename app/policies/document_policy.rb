# frozen_string_literal: true

# The DocumentPolicy class is responsible for determining what actions a user can perform on a Document record.
# It checks if the user has the necessary permissions to upload, download, or destroy a Document record.
# The permissions are determined based on the user's role and their relationship to the record.
#
# @example Checking if a user can upload a Document record
#   policy = DocumentPolicy.new(user, record)
#   policy.can_upload? #=> true
class DocumentPolicy < ApplicationPolicy
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

  # Determines if the user is allowed to modify a Document record.
  #
  # @return [Boolean] Returns true if the user has the 'modify_family' permission or if the user is the primary person of the family associated with the record.
  #
  # @example Check if a user can modify a Document record
  #   allowed_to_modify? #=> true
  #
  # @note The user is the one who is trying to perform the action. The record_user is the user who owns the record. The record is an instance of Document.
  def allowed_to_modify?
    (role.present? && role.permission.modify_family) || (user == record_user)
  end

  def role
    user&.person&.hbx_staff_role
  end

  def record_user
    case documentable
    when Eligibilities::Evidence
      documentable.applicant.family.primary_person.user
    when Person
      documentable.user
    end
  end

  def documentable
    @documentable ||= record.documentable
  end
end