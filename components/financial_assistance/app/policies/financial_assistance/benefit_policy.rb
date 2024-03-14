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

      @family ||= record._parent.application.family
      @applicant ||= record._parent
    end

    # Determines if the current user has permission to index a benefit.
    # The user can index a benefit if they have permission to perform a step.
    #
    # @return [Boolean] Returns true if the user has permission to index a benefit, false otherwise.
    def index?
      step?
    end

    # Determines if the current user has permission to perform a step.
    # The user can perform a step if they can edit the applicant associated with the benefit.
    #
    # @return [Boolean] Returns true if the user has permission to perform a step, false otherwise.
    def step?
      FinancialAssistance::ApplicantPolicy.new(user, @applicant).edit?
    end

    # Determines if the current user has permission to create a benefit.
    # The user can create a benefit if they have permission to perform a step.
    #
    # @return [Boolean] Returns true if the user has permission to create a benefit, false otherwise.
    def create?
      step?
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