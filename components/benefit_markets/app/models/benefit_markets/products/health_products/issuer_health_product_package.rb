module BenefitMarkets
  module Products
    module HealthProducts
      class IssuerHealthProductPackage < ::BenefitMarkets::Products::ProductPackage
        field :issuer_id, type: BSON::ObjectId

        validates_presence_of :issuer_id, :allow_blank => false
      end
    end
  end
end
