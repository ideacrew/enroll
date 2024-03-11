# frozen_string_literal: true

module FinancialAssistance
  # The ApplicantPolicy class defines the policy for accessing and modifying applicants.
  # It determines what actions a user can perform on an applicant based on their roles and permissions.
  class ApplicantPolicy < ::ApplicationPolicy

    # Initializes the ApplicantPolicy with a user and a record.
    # It sets the @family instance variable to the family of the application record.
    #
    # @param user [User] the user who is performing the action
    # @param record [Application] the application that the user is trying to access or modify
    def initialize(user, record)
      super
      @family ||= record.application.family
    end

    # Determines if the current user has permission to create a new application.
    # The user can create a new application if they have permission to edit it.
    #
    # @return [Boolean] Returns true if the user has permission to create a new application, false otherwise.
    def new?; end

    # Determines if the current user has permission to create an application.
    # The user can create an application if they have permission to edit it.
    #
    # @return [Boolean] Returns true if the user has permission to create an application, false otherwise.
    def create?; end

    # Determines if the current user has permission to edit an application.
    # The user can edit an application if they are a primary family member in the individual market, an active associated broker in the individual market who has verified their identity, or an admin in the individual market.
    #
    # @return [Boolean] Returns true if the user has permission to edit an application, false otherwise.
    def edit?
      return true if individual_market_primary_family_member?
      return true if active_associated_individual_market_ridp_verified_family_broker?
      return true if individual_market_admin?

      false
    end

    # Determines if the current user has permission to update an application.
    # The user can update an application if they have permission to edit it.
    #
    # @return [Boolean] Returns true if the user has permission to update an application, false otherwise.
    def update?
      edit?
    end

    # Determines if the current user has permission to answer other questions.
    # The user can answer other questions if they have permission to edit the application.
    #
    # @return [Boolean] Returns true if the user has permission to answer other questions, false otherwise.
    def other_questions?
      edit?
    end

    # Determines if the current user has permission to save questions.
    # The user can save questions if they have permission to edit the application.
    #
    # @return [Boolean] Returns true if the user has permission to save questions, false otherwise.
    def save_questions?
      edit?
    end

    # Determines if the current user has permission to perform a step.
    # The user can perform a step if they have permission to edit the application.
    #
    # @return [Boolean] Returns true if the user has permission to perform a step, false otherwise.
    def step?
      edit?
    end

    # Determines if the current user has permission to check the age of the applicant.
    # The user can check the age of the applicant if they have permission to edit the application.
    #
    # @return [Boolean] Returns true if the user has permission to check the age of the applicant, false otherwise.
    def age_of_applicant?
      edit?
    end

    # Determines if the current user has permission to check if the applicant is eligible for joint filing.
    # The user can check if the applicant is eligible for joint filing if they have permission to edit the application.
    #
    # @return [Boolean] Returns true if the user has permission to check if the applicant is eligible for joint filing, false otherwise.
    def applicant_is_eligible_for_joint_filing?
      edit?
    end

    # Determines if the current user has permission to check the immigration document options.
    # The user can check the immigration document options if they have permission to edit the application.
    #
    # @return [Boolean] Returns true if the user has permission to check the immigration document options, false otherwise.
    def immigration_document_options?
      edit?
    end

    # Determines if the current user has permission to destroy an application.
    # The user can destroy an application if they have permission to edit it.
    #
    # @return [Boolean] Returns true if the user has permission to destroy an application, false otherwise.
    def destroy?
      edit?
    end
  end
end
