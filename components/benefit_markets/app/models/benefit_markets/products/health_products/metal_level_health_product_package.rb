module BenefitMarkets
  module Products
    module HealthProducts
      class MetalLevelHealthProductPackage < ::BenefitMarkets::Products::ProductPackage
        field :metal_level, type: String

        validates_presence_of :metal_level, :allow_blank => false
      end
    end
  end
end
