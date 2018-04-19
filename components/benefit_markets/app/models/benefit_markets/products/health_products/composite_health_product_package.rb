module BenefitMarkets
  module Products
    module HealthProducts
      class CompositeHealthProductPackage < ::BenefitMarkets::Products::ProductPackage
        def all_products
          super().where("coverage_kind" => "health")
        end

        def default_product_multiplicity
          :single
        end

        def benefit_option_kind
          "composite_health"
        end
      end
    end
  end
end
