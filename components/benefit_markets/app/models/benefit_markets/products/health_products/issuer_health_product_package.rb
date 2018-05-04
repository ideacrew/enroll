module BenefitMarkets
  class Products::HealthProducts::IssuerHealthProductPackage < ::BenefitMarkets::Products::ProductPackage

    field :issuer_id, type: BSON::ObjectId
    field :premium_reference_product_id, type: BSON::ObjectId

    FILTER_MAP =  { 
                    issuer_profiles: -> { products.issuer_profiles },
                    # metal_level_kinds: BenefitMarkets::Products::HealthProducts::HealthProduct::METAL_LEVEL_KINDS,
                    health_plan_kinds: BenefitMarkets::Products::HealthProducts::HealthProduct::HEALTH_PLAN_KIND_MAP.keys,
                  }

    def all_products
      Plan.where(:active_year => packagable.product_active_year, :market => packagable.product_market_kind)
    end


    def add_product(new_product)
      raise InvalidProductKindError unless new_product.is_a?(BenefitMarkets::Products::HealthProducts::HealthProduct)

      products << new_product
    end


    # Rule definition
    #   Single Issuer
    #   Premium Reference Plan - required
    #   All available plans filtered by Issuer


# {
#     benefit_kind: :health, # => :health, :dental
#     by_issuer: "urn", #|| by_metal_level: :gold,
# }


      def is_available_for(effective_date)

        # implement by subclasses
      end


      # Filter late_rates and service_areas
      def available_products
        
      end

      def filter_late_rates
        health_products.any? { |health_product|   }
      end

      def all_products
        super().where("coverage_kind" => "health", :carrier_profile_id => issuer_id)
      end

      def benefit_option_kind
        "issuer_health"
      end

  end
end
