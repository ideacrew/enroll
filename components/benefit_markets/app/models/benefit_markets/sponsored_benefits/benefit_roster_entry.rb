module BenefitMarkets
  module SponsoredBenefits
    class BenefitRosterEntry < RosterEntry
      # Return the coverage information for this entry.
      # @return [RosterCoverage] the coverage information
      def roster_coverage
        raise NotImplementedError.new("This is a documentation only interface.")
      end
    end
  end
end
