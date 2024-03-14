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

    def can_upload?
      allowed_to_modify?
    end

    def can_download?
      allowed_to_modify?
    end

    def can_destroy?
      allowed_to_modify?
    end
  
    # Determines if the current user has permission to update evidence.
    # The user can update evidence if they have permission to perform an edit.
    #
    # @return [Boolean] Returns true if the user has permission to update evidence, false otherwise.
    def update_evidence?
      edit?
    end
  
    # Determines if the current user has permission to extend due date for evidence.
    # The user can extend due date if they have permission to perform an edit.
    #
    # @return [Boolean] Returns true if the user has permission to extend due date on evidence, false otherwise.
    def extend_due_date?
      edit?
    end

    # Determines if the current user has permission to send out the fdsh hub request.
    # The user can call fdsh hub if they have permission to perform an edit.
    #
    # @return [Boolean] Returns true if the user has permission to call out to the fdsh hub, false otherwise.
    def fdsh_hub_request?
      return true if individual_market_admin? #should this leverage hbxadmin policy instead?
    end

    # Determines if the current user has permission to perform an edit.
    # The user can perform an edit if they are a primary family member in the individual market, an active associated broker in the individual market who has verified their identity, or an admin in the individual market.
    #
    # @return [Boolean] Returns true if the user has permission to perform an edit, false otherwise.
    def edit?
      FinancialAssistance::ApplicantPolicy.new(user, @applicant).edit?
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
      role_has_permission_to_modify? || (current_user == associated_user)
    end

    def role_has_permission_to_modify?
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
      associated_family.primary_person.user
    end

    def associated_family
      record.applicant.family
    end

    def record_user
      record.applicant.family.primary_person.user
    end
  end
end