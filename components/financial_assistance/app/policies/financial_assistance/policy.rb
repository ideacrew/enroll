# frozen_string_literal: true

module FinancialAssistance
  # This class is base policy class for the FinancialAssistance component
  class Policy < ::ApplicationPolicy

    private

    def can_transform?(family)
      ridp_verified_primary_person?(family) &&
        (
          individual_market_primary_family_member?(family) ||
            active_associated_family_broker?(family) ||
            individual_market_admin?(family)
        )
    end
  end
end
