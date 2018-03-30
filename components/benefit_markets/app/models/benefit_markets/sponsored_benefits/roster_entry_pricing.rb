module BenefitMarkets
  module SponsoredBenefits
    class RosterEntryPricing
      # Return the total contribution.
      # @return [Float, BigDecimal] the contribution
      def total_contribution
        raise NotImplementedError.new("This is a documentation only interface.")
      end

      # Return a map for the contribution to each member.
      # @return [Hash<String, Float>, Hash<String, BigDecimal>] contribution by member.
      def member_contributions
        raise NotImplementedError.new("This is a documentation only interface.")
      end
    end
  end
end
