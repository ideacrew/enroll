module BenefitSponsors
  module SponsoredBenefits
    class DentalSponsoredBenefit < SponsoredBenefit

      field :elected_product_choices, type: Array  # used for choice model to store employer preferences

      def lookup_package_products(coverage_date)
        if product_package_kind == :multi_product
          BenefitMarkets::Products::Product.by_coverage_date(elected_products, coverage_date)
        else
          super
        end
      end

      def elected_products
        product_package.products.by_service_areas(recorded_service_area_ids).where(:id.in => elected_product_choices)
      end

      def renewal_elected_products_for(coverage_date)
        renewal_products = elected_products.collect(&:renewal_product)
        BenefitMarkets::Products::Product.by_coverage_date(renewal_products, coverage_date)
      end

      def attributes_for_renewal(new_benefit_package, new_product_package)
        renewal_attributes = super

        renewal_attributes.tap do |attributes|
          attributes[:elected_product_choices] = renewal_elected_products_for(new_benefit_package.start_on) if product_package_kind == :multi_product
        end
      end
    end
  end
end