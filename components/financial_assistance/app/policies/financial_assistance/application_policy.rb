# frozen_string_literal: true

module FinancialAssistance
  # The ApplicationPolicy class defines the policy for accessing financial assistance applications.
  # It provides methods to check if a user has the necessary permissions to perform various actions on an application.
  class ApplicationPolicy < Policy
    def edit?
      return true if individual_market_primary_family_member?(record.family)
      return true if active_associated_individual_market_family_broker?(record.family)
      return true if individual_market_admin?(record.family)

      false
    end
  end
end
