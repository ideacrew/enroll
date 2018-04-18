module BenefitMarkets
  module Products
    module HealthProducts
      class MetalLevelHealthProductPackage < ::BenefitMarkets::Products::ProductPackage
        field :metal_level, type: String

        validates_presence_of :metal_level, :allow_blank => false

        def all_products
          super().where("coverage_kind" => "health", :metal_level => metal_level)
        end

        def benefit_option_kind
          "metal_level_health"
        end
      end
    end
  end
end
