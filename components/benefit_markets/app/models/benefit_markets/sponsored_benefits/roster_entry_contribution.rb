module BenefitMarkets
  module SponsoredBenefits
    class RosterEntryPricing
      # Return the total pricing cost.
      # @return [BigDecimal] the cost to cover this entry
      def total_price
        raise NotImplementedError.new("This is a documentation only interface.")
      end

      # Return a map for the cost of insuring each member.
      # @return [Hash<String, Float>, Hash<String, BigDecimal>] cost by member
      def member_pricing
        raise NotImplementedError.new("This is a documentation only interface.")
      end
    end
  end
end

