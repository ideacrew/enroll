# ProductPackage provides the composite package for Benefits that may be purchased.  Site 
# exchange Admins (or seed files) define ProductPackage settings.  Benefit Catalog accesses 
# all Products via ProductPackage. 
# ProductPackage functions:
# => Provides filters for benefit display
# => Instantiates a SponsoredBenefit class for inclusion in BenefitPackage
module BenefitMarkets
  class Products::ProductPackage
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :packagable, polymorphic: true

    field :application_period,      type: Range
    field :hbx_id,                  type: String

    field :product_kind,            type: Symbol
    field :kind,                    type: Symbol
    field :title,                   type: String, default: ""
    field :description,             type: String, default: ""

    embeds_many :products,
                class_name: "BenefitMarkets::Products::Product"

    embeds_one  :contribution_model, 
                class_name: "BenefitMarkets::ContributionModels::ContributionModel"

    embeds_one  :pricing_model, 
                class_name: "BenefitMarkets::PricingModels::PricingModel"

    embeds_one  :service_area,
                class_name: "BenefitMarkets::Locations::ServiceArea"


    validates_presence_of :application_period, :product_kind, :kind
    validates_presence_of :title, :allow_blank => false

    def benefit_market_kind
      packagable.benefit_market_kind
    end

    def issuer_profiles
      return @issuer_profiles if is_defined?(@issuer_profiles)
      @issuer_profiles = products.select { |product| product.issuer_profile }.uniq!
    end

    def issuer_profile_products_for(issuer_profile)
      return @issuer_profile_products if is_defined?(@issuer_profile_products)
      @issuer_profile_products = products.collect { |issuer_profile| product.issuer_profile == issuer_profile }
    end

    # Load product subset the embedded .products list from BenefitMarket::Products using provided criteria
    def load_embedded_products(service_area, effective_date)
      products = benefit_market_products_available_for(service_area, effective_date)
    end

    # Query products from database applicable to this product package
    def all_benefit_market_products
      return unless benefit_market_kind.present? && application_period.present? && product_kind.present? && kind.present?
      return @all_benefit_market_products if is_defined?(@all_benefit_market_products)
      @all_benefit_market_products = Product.by_product_package(self)
    end

    # Intersection of BenefitMarket::Products that match both service area and effective date
    def benefit_market_products_available_for(service_area, effective_date)
      benefit_market_products_available_on(effective_date) & benefit_market_products_available_where(service_area)
    end

    # BenefitMarket::Products available for purchase on effective date
    def benefit_market_products_available_on(effective_date)
      all_benefit_market_products.collect { |product| product.premium_table_effective_on(effective_date).present? }
    end

    # BenefitMarket::Products available for purchase within a specified service area
    def benefit_market_products_available_where(service_area)
      all_benefit_market_products.collect { |product| product.service_area == service_area }
    end

    def add_product(new_product)
      products.push(new_product).uniq!
    end

    def drop_product(new_product)
      products.delete(new_product) { "not found" }
    end

  end
end
