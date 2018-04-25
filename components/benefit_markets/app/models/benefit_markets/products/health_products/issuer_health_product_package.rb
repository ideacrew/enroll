module BenefitMarkets
  module Products
    module HealthProducts
      class IssuerHealthProductPackage < ::BenefitMarkets::Products::ProductPackage
        field :issuer_id, type: BSON::ObjectId

        validates_presence_of :issuer_id, :allow_blank => false

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
