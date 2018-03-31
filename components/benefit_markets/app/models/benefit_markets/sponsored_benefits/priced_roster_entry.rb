module BenefitMarkets
  module SponsoredBenefits
    class PricedRosterEntry < BenefitRosterEntry
      # Return the pricing information for the 
      # @return [RosterEntryPricing] the pricing information
      attr_reader :roster_entry_pricing

      # Set the pricing information.
      attr_writer :roster_entry_pricing
    end
  end
end
