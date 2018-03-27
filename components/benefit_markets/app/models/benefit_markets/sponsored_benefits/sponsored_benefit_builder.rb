module BenefitMarkets
  module SponsoredBenefits
    class SponsoredBenefitBuilder

      def self.build
        builder = new
        yield(builder)
        builder.sponsored_benefit
      end

      def initialize
        @sponsored_benefit = sponsored_benefit.new
      end

      def set_kind(new_kind)
        @sponsored_benefit.kind = new_kind
      end

      def add_product_package(new_product_package)
        @sponsored_benefit.product_package = new_product_package
      end

      def add_contribution_model(new_contribution_model)
        @sponsored_benefit.contribution_model = new_contribution_model
      end

      def sponsored_benefit
        @sponsored_benefit
      end

    end
  end
end
