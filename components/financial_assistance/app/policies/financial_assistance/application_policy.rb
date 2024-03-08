# frozen_string_literal: true

module FinancialAssistance
  # The ApplicationPolicy class defines the policy for accessing financial assistance applications.
  # It provides methods to check if a user has the necessary permissions to perform various actions on an application.
  class ApplicationPolicy < Policy

    # Checks if the user can access the application.
    # A user can access the application if they are authorized to access the family associated with the application.
    #
    # @return [Boolean] Returns true if the user can access the application, false otherwise.
    def can_access_application?
      can_authorize_family?(record.family)
    end
  end
end
