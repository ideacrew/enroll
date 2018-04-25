module BenefitMarkets
  module Products
    module DentalProducts
      class SingleProductDentalProductPackage < ::BenefitMarkets::Products::ProductPackage
        def all_products
          super().where("coverage_kind" => "dental")
        end

        def default_product_multiplicity
          :single
        end

        def benefit_option_kind
          "single_product_dental"
        end
      end
    end
  end
end
