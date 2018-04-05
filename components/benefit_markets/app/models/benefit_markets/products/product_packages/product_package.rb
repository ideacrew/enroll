# ProductPackage provides the composite package for Benefits that may be purchased.  Site 
# exchange Admins (or seed files) define ProductPackage settings.  Benefit Catalog accesses 
# all Products via ProductPackage. 
# ProductPackage functions:
# => Provides filters for benefit display
# => Instantiates a SponsoredBenefit class for inclusion in BenefitPackage
module BenefitMarkets
  module Products
    module ProductPackages
      class ProductPackage
        include Mongoid::Document
        include Mongoid::Timestamps

        BENEFIT_OPTION_KINDS = [
          :any_dental,
          :single_product_health,
          :single_product_dental,
          :issuer_health,
          :metal_level_health,
          :composite_health
        ]

        field :reference, type: Symbol

        field :hbx_id,                  type: String
        field :title,                   type: String
        field :contribution_model_id, type: BSON::ObjectId
        field :pricing_model_id, type: BSON::ObjectId
        field :product_year, type: String

        belongs_to  :benefit_catalog, class_name: "BenefitMarkets::BenefitMarketCatalog"

        validates_presence_of :title
        validates_presence_of :product_year, :allow_blank => false

        def self.subclass_for(benefit_option_kind)
          "::BenefitMarkets::Products::ProductPackages::#{benefit_option_kind.to_s.camelcase}ProductPackage".constantize
        end
      end
    end
  end
end
