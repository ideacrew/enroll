module BenefitMarkets
  module SponsoredBenefits
    # This is an abstract class that represents and documents the interface
    # which must be satisfied by objects returned by any implementation
    # of BenefitRosterEntry, via the #roster_coverage method
    class RosterCoverage
      # Return the date on which the rate schedule is applicable.
      # @return [Date] the rate schedule date
      def rate_schedule_date
        raise NotImplementedError.new("This is a documentation only interface.")
      end

      # The coverage start date.
      # @return [Date] the coverage start date
      def coverage_start_date
        raise NotImplementedError.new("This is a documentation only interface.")
      end

      # Return the date from which the premium is eligible to be calculated
      # for each member.
      # Can differ from the coverage_start_date for the group.
      # It is this rate date that should be used for the 'age on coverage'
      # calculation.
      # @return [Hash<String, Date>] a map of member id to coverage
      #   eligibility date.
      def coverage_eligibility_dates
        raise NotImplementedError.new("This is a documentation only interface.")
      end

      # The selected product.
      # @return [::BenefitMarkets::Products::Product] the product
      def product
        raise NotImplementedError.new("This is a documentation only interface.")
      end
    end
  end
end
