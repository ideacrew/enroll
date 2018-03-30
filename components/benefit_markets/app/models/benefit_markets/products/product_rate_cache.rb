module BenefitMarkets
  module Products
    # Provides a cached, efficient lookup for referencing rate values
    # by multiple keys.
    class ProductRateCache
      # Return the base rate value from the product cache.
      # @param product [Product] the product for which I desire the value
      # @param rate_schedule_date [Date] the date on which the rate schedule
      #   should be active
      # @param coverage_age [Integer] the age of the covered party on the
      #   applicable date
      # @param rating_area [String] the rating area in which the rates apply
      # @return [Float, BigDecimal] the basis rate
      def self.lookup_rate(
        product,
        rate_schedule_date,
        coverage_age,
        rating_area
      )
        raise NotImplementedError.new("we haven't written this yet")
      end
    end
  end
end
