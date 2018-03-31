module BenefitSponsors
  module BenefitPackages
    class TransformProductPackageToSponsoredBenefit

      attr_reader :product_package, :benefit_package


      def initialize(benefit_package)

        get_product_package
        build_health_sponsored_benefit

      end
    end
  end
end
