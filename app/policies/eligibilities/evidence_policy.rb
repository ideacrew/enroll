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
    # Initializes the EvidencePolicy with a user and a record.
    # It sets the @family instance variable to the family of the application record.
    #
    # @param user [User] the user who is performing the action
    # @param record [Evidence] the evidence that the user is trying to access or modify
    def initialize(user, record)
      super

      # @todo Replace _parent with applicant. For some reason, the applicant is returning `nil`.
      #   The applicant is supposed to be a FinancialAssistance::Applicant object.
      #   Currently, the _parent method is being used, which returns the FinancialAssistance::Application object.
      @family ||= record._parent.application.family
      @applicant ||= record._parent
    end

    # Determines if the current user has permission to extend due date for evidence.
    # The user can extend due date if they have permission to edit the associated Applicant.
    #
    # @return [Boolean] Returns true if the user has permission to extend due date on evidence, false otherwise.
    def extend_due_date?
      HbxProfilePolicy.new(user, @applicant).can_extend_due_date?
    end

    # Determines if the current user has permission to send out the fdsh hub request.
    # The user can call fdsh hub if they are an individual market admin.
    #
    # @return [Boolean] Returns true if the user has permission to call out to the fdsh hub, false otherwise.
    def fdsh_hub_request?
      HbxProfilePolicy.new(user, @applicant).can_extend_due_date?
    end
  end
end