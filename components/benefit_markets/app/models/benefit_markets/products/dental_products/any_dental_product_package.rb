module BenefitMarkets
  module Products
    module DentalProducts
      class AnyDentalProductPackage < ::BenefitMarkets::Products::ProductPackage
        def all_products
          super().where("coverage_kind" => "dental")
        end

        def benefit_option_kind
          "any_dental"
        end
      end
    end
  end
end
