module BenefitMarkets
  module Products
    module DentalProducts
      class SingleProductDentalProductPackage < ::BenefitMarkets::Products::ProductPackage
        def all_products
          super().where("coverage_kind" => "dental")
        end
      end
    end
  end
end
