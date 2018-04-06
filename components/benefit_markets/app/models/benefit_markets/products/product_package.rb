# ProductPackage provides the composite package for Benefits that may be purchased.  Site 
# exchange Admins (or seed files) define ProductPackage settings.  Benefit Catalog accesses 
# all Products via ProductPackage. 
# ProductPackage functions:
# => Provides filters for benefit display
# => Instantiates a SponsoredBenefit class for inclusion in BenefitPackage
module BenefitMarkets
  module Products
      class ProductPackage
        include Mongoid::Document
        include Mongoid::Timestamps

        BENEFIT_PACKAGE_MAPPINGS = {
          :any_dental => ["dental", "any"],
          :single_product_health => ["health", "single_product"],
          :single_product_dental => ["dental", "single_product"],
          :issuer_health => ["health", "issuer"],
          :metal_level_health => ["health", "metal_level"],
          :composite_health => ["health", "composite"]
        }

        BENEFIT_OPTION_KINDS = BENEFIT_PACKAGE_MAPPINGS.keys

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
          product_kind, constraint = BENEFIT_PACKAGE_MAPPINGS[benefit_option_kind.to_sym]
          "::BenefitMarkets::Products::#{product_kind.to_s.camelcase}Products::#{constraint.to_s.camelcase}#{product_kind.to_s.camelcase}ProductPackage".constantize
        end
      end
    end
end
