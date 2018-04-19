module BenefitSponsors
  module Forms
    class SponsoredBenefit
      attr_accessor :benefit_application, :product_package

      def initialize(benefit_application, product_package)
        @benefit_application = benefit_application
        @product_package = product_package

        build_sponsored_benefit
      end

      def build_sponsored_benefit
      end
    end
  end
end
