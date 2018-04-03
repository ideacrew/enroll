module BenefitSponsors
  class SponsoredBenefits::ProductPackageToSponsorContributionService
    include Mongoid::Document


      def product_kind=(new_product_kind)
        validate_product_kind!(new_product_kind)

        @sponsored_benefit 
        @product_kind = new_product_kind
      end

      def product_package_kind=(new_product_package_kind)
        validate_product_package_kind!(new_product_package_kind)
        @product_package_kind = new_product_package_kind
      end
  end
end
