module BenefitMarkets
  module Products
    module HealthProducts
      class IssuerHealthProductPackage < ::BenefitMarkets::Products::ProductPackage

        # field :issuer_id, type: BSON::ObjectId

        belongs_to  :issuer
        embeds_many :health_products,
                    as: :products,
                    class_name: "BenefitMarkets::Products::HealthProducts"

        validates_presence_of :issuer_id, :allow_blank => false


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
  end
end
