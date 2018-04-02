module BenefitMarkets
  module SponsoredBenefits
    class ContributionRosterEntry < PricedRosterEntry
      # Return the contribution information for this entry.
      # @return [RosterEntryContribution] the contribution information
      attr_reader :roster_entry_contribution
      
      # Set the contribution information.
      attr_writer :roster_entry_contribution
    end
  end
end
