# frozen_string_literal: true

module FinancialAssistance
  # This class is base policy class for the FinancialAssistance component
  class Policy < ::ApplicationPolicy

    private

    def can_authorize_family?(family)
      ::FamilyPolicy.new(user, family).can_authorize_individual_market_family?
    end
  end
end
