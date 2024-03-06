# frozen_string_literal: true

module FinancialAssistance
  # The ApplicantPolicy class defines the policy for accessing applicants in the financial assistance module.
  # It extends from the Policy class.
  class ApplicantPolicy < Policy
    # Checks if the user can view and modify the applicant.
    # The user can view and modify the applicant if the consumer role associated with the primary person of the application's family is not blank,
    # and the consumer role is RIDP verified and has the permission to view and modify.
    #
    # @return [Boolean] Returns true if the user can view and modify the applicant, false otherwise.
    def can_access_endpoint?
      consumer_role = record.application.family.primary_person.consumer_role
      return false if consumer_role.blank?

      consumer_policy = ::ConsumerRolePolicy.new(user, consumer_role)
      consumer_policy.ridp_verified? && (consumer_policy.modify_and_view_as_self_or_broker? || consumer_policy.hbx_staff_modify_family?)
    end
  end
end
