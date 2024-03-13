# frozen_string_literal: true

# FinancialAssistance module encapsulates all the models used in the Financial Assistance feature
module FinancialAssistance
    # The EvidencePolicy class defines the policy for accessing and modifying evidence.
    # It determines what actions a user can perform on a deduction based on their roles and permissions.
    class EvidencePolicy < ::ApplicationPolicy
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
  
      # Determines if the current user has permission to perform an edit.
      # The user can perform an edit if they are a primary family member in the individual market, an active associated broker in the individual market who has verified their identity, or an admin in the individual market.
      #
      # @return [Boolean] Returns true if the user has permission to perform an edit, false otherwise.
      def edit?
        FinancialAssistance::ApplicantPolicy.new(user, @applicant).edit?
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
    end
  end
  