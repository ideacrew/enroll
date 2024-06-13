# frozen_string_literal: true

module FinancialAssistance
  # The ApplicationPolicy class defines the policy for accessing financial assistance applications.
  # It provides methods to check if a user has the necessary permissions to perform various actions on an application.
  class ApplicationPolicy < ::ApplicationPolicy

    # Initializes the ApplicationPolicy with a user and a record.
    # It sets the @family instance variable to the family of the record.
    #
    # @param user [User] the user who is performing the action
    # @param record [Application] the application that the user is trying to access or modify
    def initialize(user, record)
      super
      @family ||= record.family
    end

    # Determines if the current user has permission to create an application.
    # The user can create an application if they have permission to edit it.
    #
    # @return [Boolean] Returns true if the user has permission to create an application, false otherwise.
    def create?
      edit?
    end

    # Determines if the current user has permission to edit.
    # The user can edit if they are a primary family member,
    # an active associated broker staff, an active associated broker, or an admin in the individual market.
    #
    # @return [Boolean] Returns true if the user has permission to edit, false otherwise.
    def edit?
      return true if individual_market_primary_family_member?
      return true if active_associated_individual_market_family_broker_staff?
      return true if active_associated_individual_market_family_broker?
      return true if individual_market_admin?

      false
    end

    # Determines if the current user has permission to view the index page.
    # The user can view the index page if they have permission to edit.
    #
    # @return [Boolean] Returns true if the user has permission to view the index page, false otherwise.
    def index?
      edit?
    end

    # Determines if the current user has permission to proceed to the next step of the application.
    # The user can proceed if they have permission to edit the application.
    #
    # @return [Boolean] Returns true if the user has permission to proceed to the next step of the application, false otherwise.
    def step?
      edit?
    end

    # Determines if the current user has permission to get to the preferences page of the application.
    # The user can proceed if they have permission to edit the application.
    #
    # @return [Boolean] Returns true if the user has permission to proceed to get to the preferences page of the application, false otherwise.
    def preferences?
      edit?
    end

    # Determines if the current user has permission to save the preferences page of the application.
    # The user can proceed if they have permission to edit the application.
    #
    # @return [Boolean] Returns true if the user has permission to proceed to save the preferences page of the application, false otherwise.
    def save_preferences?
      edit?
    end

    # Determines if the current user has permission to get to the submit your application page of the application.
    # The user can proceed if they have permission to edit the application.
    #
    # @return [Boolean] Returns true if the user has permission to proceed to get to the submit your application page of the application, false otherwise.
    def submit_your_application?
      edit?
    end

    # Determines if the current user has permission to submit the application.
    # The user can proceed if they have permission to edit the application.
    #
    # @return [Boolean] Returns true if the user has permission to submit the application, false otherwise.
    def submit?
      edit?
    end

    # Determines if the current user has permission to copy the application.
    # The user can copy the application if they have permission to edit it.
    #
    # @return [Boolean] Returns true if the user has permission to copy the application, false otherwise.
    def copy?
      edit?
    end

    # Determines if the current user has permission to select the application year.
    # The user can select the year if they have permission to edit the application.
    #
    # @return [Boolean] Returns true if the user has permission to select the application year, false otherwise.
    def application_year_selection?
      edit?
    end

    # Determines if the current user has permission to view the application checklist.
    # The user can view the checklist if they have permission to edit the application.
    #
    # @return [Boolean] Returns true if the user has permission to view the application checklist, false otherwise.
    def application_checklist?
      edit?
    end

    # Determines if the current user has permission to review and submit the application.
    # The user can review and submit the application if they have permission to edit it.
    #
    # @return [Boolean] Returns true if the user has permission to review and submit the application, false otherwise.
    def review_and_submit?
      edit?
    end

    # Determines if the current user has permission to review the application.
    # The user can review the application if they have permission to edit it.
    #
    # @return [Boolean] Returns true if the user has permission to review the application, false otherwise.
    def review?
      edit?
    end

    # Determines if the current user has permission to wait for the eligibility response of the application.
    # The user can wait for the eligibility response if they have permission to edit the application.
    #
    # @return [Boolean] Returns true if the user has permission to wait for the eligibility response of the application, false otherwise.
    def wait_for_eligibility_response?
      edit?
    end

    # Determines if the current user has permission to view the eligibility results of the application.
    # The user can view the eligibility results if they have permission to edit the application.
    #
    # @return [Boolean] Returns true if the user has permission to view the eligibility results of the application, false otherwise.
    def eligibility_results?
      edit?
    end

    # Determines if the current user has permission to view the application publish error.
    # The user can view the error if they have permission to edit the application.
    #
    # @return [Boolean] Returns true if the user has permission to view the application publish error, false otherwise.
    def application_publish_error?
      edit?
    end

    # Determines if the current user has permission to view the eligibility response error of the application.
    # The user can view the error if they have permission to edit the application.
    #
    # @return [Boolean] Returns true if the user has permission to view the eligibility response error of the application, false otherwise.
    def eligibility_response_error?
      edit?
    end

    # Determines if the current user has permission to check if the eligibility results of the application have been received.
    # The user can check if the results have been received if they have permission to edit the application.
    #
    # @return [Boolean] Returns true if the user has permission to check if the eligibility results of the application have been received, false otherwise.
    def check_eligibility_results_received?
      edit?
    end

    # Determines if the current user has permission to view the application checklist in PDF format.
    # The user can view the checklist in PDF format if they have permission to edit the application.
    #
    # @return [Boolean] Returns true if the user has permission to view the application checklist in PDF format, false otherwise.
    def checklist_pdf?
      edit?
    end

    # Determines if the current user has permission to update the transfer requested status of the application.
    # The user can update the status if they have permission to edit the application.
    #
    # @return [Boolean] Returns true if the user has permission to update the transfer requested status of the application, false otherwise.
    def update_transfer_requested?
      edit?
    end

    # Determines if the current user has permission to update the application year.
    # The user can update the year if they have permission to edit the application.
    #
    # @return [Boolean] Returns true if the user has permission to update the application year, false otherwise.
    def update_application_year?
      edit?
    end
  end
end
