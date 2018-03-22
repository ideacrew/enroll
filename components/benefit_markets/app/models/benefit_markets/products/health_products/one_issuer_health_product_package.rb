module BenefitMarkets
  module Products
    module HealthProducts
      class OneIssuerHealthProductPackage < BenefitMarkets::Products::ProductPackage

        embeds_one :reference_plan, class_name: "BenefitMarkets::Products::HealthProducts::HealthProduct"

        validates_presence_of :reference_plan

        def product_list_for(issuer, effective_date = TimeKeeper.date_of_record)
        end


      end
    end
  end
end
