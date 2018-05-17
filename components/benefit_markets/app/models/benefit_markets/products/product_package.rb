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
    field :product_kind,            type: Symbol
    field :kind,                    type: Symbol
    field :title,                   type: String, default: ""
    field :description,             type: String, default: ""
    field :multiplicity,            type: Boolean, default: true

    embeds_many :products,
                class_name: "BenefitMarkets::Products::Product"

    embeds_one  :contribution_model, 
                class_name: "BenefitMarkets::ContributionModels::ContributionModel"

    embeds_one  :pricing_model, 
                class_name: "BenefitMarkets::PricingModels::PricingModel"

    validates_presence_of :product_kind, :kind, :application_period
    validates_presence_of :title, :allow_blank => false

    scope :by_kind,             ->(kind){ where(kind: kind) }
    scope :by_product_kind,     ->(product_kind) { where(product_kind: product_kind) }


    def effective_date
      packagable.effective_date || application_period.min
    end

    def benefit_market_kind
      packagable.benefit_market_kind
    end

    def product_multiplicity
      multiplicity ? :multiple : :single
    end

    def active_products
      products.active_on(effective_date)
    end

    def issuer_profiles
      return @issuer_profiles if defined?(@issuer_profiles)
      @issuer_profiles = active_products.select { |product| product.issuer_profile }.uniq!
    end

    def issuer_profile_products_for(issuer_profile)
      return @issuer_profile_products if defined?(@issuer_profile_products)
      @issuer_profile_products = active_products.by_issuer_profile(issuer_profile)
    end

    # Load product subset the embedded .products list from BenefitMarket::Products using provided criteria
    def load_embedded_products(service_area, effective_date)
      products = benefit_market_products_available_for(service_area, effective_date)
    end

    # Query products from database applicable to this product package
    def all_benefit_market_products
      raise StandardError, "Product package is invalid" unless benefit_market_kind.present? && application_period.present? && product_kind.present? && kind.present?
      return @all_benefit_market_products if defined?(@all_benefit_market_products)
      @all_benefit_market_products = BenefitMarkets::Products::Product.by_product_package(self)
    end

    # Intersection of BenefitMarket::Products that match both service area and effective date
    def benefit_market_products_available_for(service_area, effective_date)
      benefit_market_products_available_on(effective_date)# & benefit_market_products_available_where(service_area)
    end

    # BenefitMarket::Products available for purchase on effective date
    def benefit_market_products_available_on(effective_date)
      all_benefit_market_products.select { |product| product.premium_table_effective_on(effective_date).present? }
    end

    # BenefitMarket::Products available for purchase within a specified service area
    def benefit_market_products_available_where(service_area)
      all_benefit_market_products.select { |product| product.service_area == service_area }
    end

    def products_for_plan_option_choice(product_option_choice)
      if kind == :metal_level
        products.by_metal_level(product_option_choice)
      else
        issuer_profile = BenefitSponsors::Organizations::IssuerProfile.find_by_issuer_name(product_option_choice)
        return [] unless issuer_profile
        issuer_profile_products_for(issuer_profile)
      end
    end

    def add_product(new_product)
      products.push(new_product).uniq!
    end

    def drop_product(new_product)
      products.delete(new_product) { "not found" }
    end

  end
end
