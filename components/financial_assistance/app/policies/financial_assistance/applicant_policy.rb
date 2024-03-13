# frozen_string_literal: true

module FinancialAssistance
  # The ApplicantPolicy class defines the policy for accessing and modifying applicants.
  # It determines what actions a user can perform on an applicant based on their roles and permissions.
  class ApplicantPolicy < ::ApplicationPolicy

    # Initializes the ApplicantPolicy with a user and a record.
    # It sets the @family instance variable to the family of the applicant record.
    #
    # @param user [User] the user who is performing the action
    # @param record [Applicant] the applicant that the user is trying to access or modify
    def initialize(user, record)
      super
      @family ||= record.application.family
    end

    # Determines if the current user has permission to create a new applicant.
    # The user can create a new applicant if they have permission to edit it.
    #
    # @return [Boolean] Returns true if the user has permission to create a new applicant, false otherwise.
    def new?
      edit?
    end

    # Determines if the current user has permission to create an applicant.
    # The user can create an applicant if they have permission to edit it.
    #
    # @return [Boolean] Returns true if the user has permission to create an applicant, false otherwise.
    def create?
      edit?
    end

    # Determines if the current user has permission to edit an applicant.
    # The user can edit an applicant if they are a primary family member in the individual market, an active associated broker in the individual market who has verified their identity, or an admin in the individual market.
    #
    # @return [Boolean] Returns true if the user has permission to edit an applicant, false otherwise.
    def edit?
      return true if individual_market_primary_family_member?
      return true if active_associated_individual_market_ridp_verified_family_broker?
      return true if individual_market_admin?

      false
    end

    # Determines if the current user has permission to index an applicant.
    # The user can index an applicant if they have permission to edit it.
    #
    # @return [Boolean] Returns true if the user has permission to index an applicant, false otherwise.
    def index?
      edit?
    end

    # Determines if the current user has permission to update an applicant.
    # The user can update an applicant if they have permission to edit it.
    #
    # @return [Boolean] Returns true if the user has permission to update an applicant, false otherwise.
    def update?
      edit?
    end

    # Determines if the current user has permission to answer other questions.
    # The user can answer other questions if they have permission to edit the applicant.
    #
    # @return [Boolean] Returns true if the user has permission to answer other questions, false otherwise.
    def other_questions?
      edit?
    end

    # Determines if the current user has permission to save questions.
    # The user can save questions if they have permission to edit the applicant.
    #
    # @return [Boolean] Returns true if the user has permission to save questions, false otherwise.
    def save_questions?
      edit?
    end

    # Determines if the current user has permission to perform a step.
    # The user can perform a step if they have permission to edit the applicant.
    #
    # @return [Boolean] Returns true if the user has permission to perform a step, false otherwise.
    def step?
      edit?
    end

    # Determines if the current user has permission to check the age of the applicant.
    # The user can check the age of the applicant if they have permission to edit the applicant.
    #
    # @return [Boolean] Returns true if the user has permission to check the age of the applicant, false otherwise.
    def age_of_applicant?
      edit?
    end

    # Determines if the current user has permission to check if the applicant is eligible for joint filing.
    # The user can check if the applicant is eligible for joint filing if they have permission to edit the applicant.
    #
    # @return [Boolean] Returns true if the user has permission to check if the applicant is eligible for joint filing, false otherwise.
    def applicant_is_eligible_for_joint_filing?
      edit?
    end

    # Determines if the current user has permission to check the immigration document options.
    # The user can check the immigration document options if they have permission to edit the applicant.
    #
    # @return [Boolean] Returns true if the user has permission to check the immigration document options, false otherwise.
    def immigration_document_options?
      edit?
    end

    # Determines if the current user has permission to destroy an applicant.
    # The user can destroy an applicant if they have permission to edit it.
    #
    # @return [Boolean] Returns true if the user has permission to destroy an applicant, false otherwise.
    def destroy?
      edit?
    end

    # Determines if the current user has permission to other an applicant.
    # The user can other an applicant if they have permission to edit it.
    #
    # @return [Boolean] Returns true if the user has permission to other an applicant, false otherwise.
    def other?
      edit?
    end
  end
end
