# frozen_string_literal: true

module Eligibilities
  class EvidencePolicy < ApplicationPolicy
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

    def allowed_to_modify?
      (role.present? && role.permission.modify_family) || (user == record_user)
    end

    def role
      user&.person&.hbx_staff_role
    end

    def record_user
      record.applicant.family.primary_person.user
    end
  end
end