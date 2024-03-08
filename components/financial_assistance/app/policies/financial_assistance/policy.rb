# frozen_string_literal: true

module FinancialAssistance
  # This class is base policy class for the FinancialAssistance component
  class Policy < ::ApplicationPolicy

    private

    # Checks if the user can authorize the given family.
    # A user can authorize the family if they can access the individual market for the family.
    #
    # @param family [Family] The family to check.
    # @return [Boolean] Returns true if the user can authorize the family, false otherwise.
    def can_authorize_family?(family)
      ::FamilyPolicy.new(user, family).can_access_individual_market?
    end
  end
end
