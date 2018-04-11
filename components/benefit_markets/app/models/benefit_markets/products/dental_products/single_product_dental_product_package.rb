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
      end
    end
  end
end
