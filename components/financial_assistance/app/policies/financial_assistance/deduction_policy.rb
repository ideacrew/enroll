# frozen_string_literal: true

# FinancialAssistance module encapsulates all the models used in the Financial Assistance feature
module FinancialAssistance
  # The DeductionPolicy class defines the policy for accessing and modifying deductions.
  # It determines what actions a user can perform on a deduction based on their roles and permissions.
  class DeductionPolicy < ::ApplicationPolicy
    # Initializes the DeductionPolicy with a user and a record.
    # It sets the @family instance variable to the family of the application record.
    #
    # @param user [User] the user who is performing the action
    # @param record [Deduction] the deduction that the user is trying to access or modify
    def initialize(user, record)
      super

      # @todo Replace _parent with applicant. For some reason, the applicant is returning `nil`.
      #   The applicant is supposed to be a FinancialAssistance::Applicant object.
      #   Currently, the _parent method is being used, which returns the FinancialAssistance::Application object.
      @family ||= record._parent.application.family
    end

    # Determines if the current user has permission to proceed to the next step in the deduction process.
    # The user can proceed if they are a primary family member,
    # an active associated broker staff, an active associated broker, or an admin in the individual market.
    #
    # @return [Boolean] Returns true if the user has permission to proceed to the next step, false otherwise.
    def step?
      return true if individual_market_primary_family_member?
      return true if active_associated_individual_market_family_broker_staff?
      return true if active_associated_individual_market_family_broker?
      return true if individual_market_admin?

      false
    end

    # Determines if the current user has permission to update a deduction.
    # The user can update a deduction if they have permission to perform a step.
    #
    # @return [Boolean] Returns true if the user has permission to update a deduction, false otherwise.
    def update?
      step?
    end

    # Determines if the current user has permission to destroy a deduction.
    # The user can destroy a deduction if they have permission to perform a step.
    #
    # @return [Boolean] Returns true if the user has permission to destroy a deduction, false otherwise.
    def destroy?
      step?
    end
  end
end
