# frozen_string_literal: true

module FinancialAssistance
  # The ApplicationPolicy class defines the policy for accessing financial assistance applications.
  # It provides methods to check if a user has the necessary permissions to perform various actions on an application.
  class ApplicationPolicy < Policy
    def edit?
      ::FamilyPolicy.new(user, record.family).edit?
    end
  end
end
