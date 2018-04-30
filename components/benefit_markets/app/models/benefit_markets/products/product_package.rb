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
        field :product_multiplicity, type: Symbol, default: ->() { default_product_multiplicity }

        belongs_to :contribution_model, class_name: "::BenefitMarkets::ContributionModels::ContributionModel"
        belongs_to :pricing_model, class_name: "::BenefitMarkets::PricingModels::PricingModel"

        embedded_in :benefit_catalog, class_name: "::BenefitMarkets::BenefitMarketCatalog"

        validates_presence_of :title, :allow_blank => false
        validates_presence_of :benefit_catalog_id, :allow_blank => false
        validate :has_products

        def default_product_multiplicity 
          :multiple
        end

        def self.subclass_for(benefit_option_kind)
          product_kind, constraint = BENEFIT_PACKAGE_MAPPINGS[benefit_option_kind.to_sym]
          "::BenefitMarkets::Products::#{product_kind.to_s.camelcase}Products::#{constraint.to_s.camelcase}#{product_kind.to_s.camelcase}ProductPackage".constantize
        end

        def has_products
          return true if benefit_catalog_id.blank?
          if self.all_products.empty?
            self.errors.add(:base, "the package would have no products")
            false
          else
            true
          end
        end

        # Override this once the actual product implementation is available
        def all_products
          Plan.where(:active_year => benefit_catalog.product_active_year, :market => benefit_catalog.product_market_kind)
        end

        def benefit_package_kind
          raise NotImplementedError.new("subclass responsibility")
        end

        def policy_class
          ::BenefitMarkets::Products::ProductPackagePolicy
        end
      end
    end
end
