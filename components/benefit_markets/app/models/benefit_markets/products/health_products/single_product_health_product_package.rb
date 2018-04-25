module BenefitMarkets
  module Products
    module HealthProducts
      class SingleProductHealthProductPackage < ::BenefitMarkets::Products::ProductPackage
        def all_products
          super().where("coverage_kind" => "health")
        end

        def default_product_multiplicity
          :single
        end

        def benefit_option_kind
          "single_product_health"
        end
      end
    end
  end
end
