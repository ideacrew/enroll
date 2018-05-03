# ProductPackage provides the composite package for Benefits that may be purchased.  Site 
# exchange Admins (or seed files) define ProductPackage settings.  Benefit Catalog accesses 
# all Products via ProductPackage. 
# ProductPackage functions:
# => Provides filters for benefit display
# => Instantiates a SponsoredBenefit class for inclusion in BenefitPackage
module BenefitMarkets
  module Products::ProductPackage
        include Mongoid::Document
        include Mongoid::Timestamps

        embedded_in :benefit_market_catalog,
                    class_name: "::BenefitMarkets::BenefitMarketCatalog"


        field :key,                     type: Symbol
        field :hbx_id,                  type: String
        field :title,                   type: String
        field :description,             type: String

        field :product_multiplicity,    type: Symbol, default: ->() { default_product_multiplicity }

        embeds_many :products,
                    class_name: "BenefitMarkets::Products::Product"

        embeds_one  :contribution_model, 
                    class_name: "::BenefitMarkets::ContributionModels::ContributionModel"

        embeds_one  :pricing_model, 
                    class_name: "::BenefitMarkets::PricingModels::PricingModel"


        validates_presence_of :title, :allow_blank => false
        # validates_presence_of :benefit_catalog_id, :allow_blank => false
        validate :has_products

        # Intersection of product that match service area and effective dates
        def products_available_for?(service_area, effective_date)
          products_available_on(effective_date) & products_available_where(service_area)
        end

        def products_available_on(effective_date)
          products.collect { |product| product.premium_table_effective_on(effective_date).present? }
        end

        def products_available_where(service_area)
          products.collect { |product| product.service_area == service_area }
        end

        def is_available_for?(service_area, effective_date)
          # check the 
          #implement by subclasses
          true
        end

        def default_product_multiplicity 
          :multiple
        end

        def self.subclass_for(benefit_option_kind)
          product_kind, constraint = BENEFIT_PACKAGE_MAPPINGS[benefit_option_kind.to_sym]
          "::BenefitMarkets::Products::#{product_kind.to_s.camelcase}Products::#{constraint.to_s.camelcase}#{product_kind.to_s.camelcase}ProductPackage".constantize
        end

        def has_products
          return true if benefit_catalog.blank?
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
          # Implement in subclass
        end

        def policy_class
          ::BenefitMarkets::Products::ProductPackagePolicy
        end
      end
    end

        BENEFIT_PACKAGE_MAPPINGS = {
          :any_dental             => [:dental, :any],
          :single_product_health  => [:health, :single_product],
          :single_product_dental  => [:dental, :single_product],
          :issuer_health          => [:health, :issuer],
          :metal_level_health     => [:health, :metal_level],
          :composite_health       => [:health, :composite]
        }

        BENEFIT_OPTION_KINDS = BENEFIT_PACKAGE_MAPPINGS.keys


end
