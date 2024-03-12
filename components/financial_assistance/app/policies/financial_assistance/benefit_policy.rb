# frozen_string_literal: true

# FinancialAssistance module encapsulates all the models used in the Financial Assistance feature
module FinancialAssistance
  # The BenefitPolicy class defines the policy for accessing and modifying benefits associated with a Financial Assistance Applicant.
  # It determines what actions a user can perform on a benefit based on their roles and permissions.
  class BenefitPolicy < ::ApplicationPolicy

  # Initializes the BenefitPolicy with a user and a record.
  # It sets the @family instance variable to the family of the application record.
  #
  # @param user [User] the user who is performing the action
  # @param record [Benefit] the benefit that the user is trying to access or modify
    def initialize(user, record)
      super

      # @todo Replace _parent with applicant. For some reason, the applicant is returning `nil`.
      #   The applicant is supposed to be a FinancialAssistance::Applicant object.
      #   Currently, the _parent method is being used, which returns the FinancialAssistance::Application object.
      @family ||= record._parent.application.family
    end

  # Determines if the current user has permission to perform a step.
  # The user can perform a step if they are a primary family member in the individual market, an active associated broker in the individual market who has verified their identity, or an admin in the individual market.
  #
  # @return [Boolean] Returns true if the user has permission to perform a step, false otherwise.
    def step?
      return true if individual_market_primary_family_member?
      return true if active_associated_individual_market_ridp_verified_family_broker?
      return true if individual_market_admin?

      false
    end

    # Determines if the current user has permission to update a benefit.
    # The user can update a benefit if they have permission to perform a step.
    #
    # @return [Boolean] Returns true if the user has permission to update a benefit, false otherwise.
    def update?
      step?
    end

    # Determines if the current user has permission to destroy a benefit.
    # The user can destroy a benefit if they have permission to perform a step.
    #
    # @return [Boolean] Returns true if the user has permission to destroy a benefit, false otherwise.
    def destroy?
      step?
    end
  end
end