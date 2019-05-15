module BenefitSponsors
  module SponsoredBenefits
    class DentalSponsoredBenefit < SponsoredBenefit

      field :elected_product_choices, type: Array  # used for choice model to store employer preferences

      def lookup_package_products(coverage_date)
        if product_package_kind == :multi_product
          package_products = product_package.products.by_service_areas(recorded_service_area_ids).select do |product|
            elected_product_choices.include?(product.id.to_s)
          end
          BenefitMarkets::Products::Product.by_coverage_date(package_products, coverage_date)
        else
          super
        end
      end
    end
  end
end
