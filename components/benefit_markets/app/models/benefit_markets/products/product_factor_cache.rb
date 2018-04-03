module BenefitMarkets
  module Products
    # Provides a cached, efficient lookup for referencing rate values
    # by multiple keys.
    class ProductFactorCache
      # Return the sic code factor value for a given product.
      # @param product [Product] the product for which I desire the value
      # @param sic_code [String] the SIC code
      # @return [Float, BigDecimal] the factor
      def self.lookup_sic_code_factor(
        product,
        sic_code
      )
        1.0
      end
      
      # Return the group size factor value for a given product.
      # @param product [Product] the product for which I desire the value
      # @param group_size [String] the group size
      # @return [Float, BigDecimal] the factor
      def self.lookup_group_size_factor(
        product,
        group_size
      )
        1.0
      end
      
      # Return the participation percent factor value for a given product.
      # @param product [Product] the product for which I desire the value
      # @param participation_percent [String] the participation_percent
      # @return [Float, BigDecimal] the factor
      def self.lookup_participation_percent_factor(
        product,
        participation_percent 
      )
        1.0
      end
 
      # Return the rating tier factor value for a given product.
      # @param product [Product] the product for which I desire the value
      # @param rating_tier_name [String] the rating_tier_name
      # @return [Float, BigDecimal] the factor
      def self.lookup_composite_tier_factor(
        product,
        participation_percent 
      )
        1.0
      end
    end
  end
end
