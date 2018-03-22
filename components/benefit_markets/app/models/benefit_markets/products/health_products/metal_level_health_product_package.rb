module BenefitMarkets
  module Products
    module HealthProducts
      class MetalLevelHealthProductPackage < BenefitMarkets::Products::ProductPackage


        embeds_one :reference_plan, class_name: "BenefitMarkets::Products::HealthProducts::HealthProduct"


        validates_presence_of :reference_plan

        def product_list_for(metal_level, effective_date = TimeKeeper.date_of_record)
        end

      end
    end
  end
end
