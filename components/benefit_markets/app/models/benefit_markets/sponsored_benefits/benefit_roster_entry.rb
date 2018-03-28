module BenefitMarkets
  module SponsoredBenefits
    # This is an abstract class that represents and documents the interface
    # which must be satisfied by objects returned by any implementation of
    # BenefitRoster's #each method.
    class BenefitRosterEntry
      # Return the roster entry information.
      # @return [RosterEntry] the roster entry information
      def roster_entry
        raise NotImplementedError.new("This is a documentation only interface.")
      end

      # Return the date from which the premium is eligible to be calculated.
      # Can differ from the coverage_start_date for the group.
      # It is this rate date that should be used for the 'age on coverage'
      # calculation.
      # @return [Date] the coverage eligibility date
      def coverage_eligibility_date
        raise NotImplementedError.new("This is a documentation only interface.")
      end

      # Return the coverage information for this entry.
      # @return [RosterCoverage] the coverage information
      def roster_coverage
        raise NotImplementedError.new("This is a documentation only interface.")
      end
    end
  end
end
