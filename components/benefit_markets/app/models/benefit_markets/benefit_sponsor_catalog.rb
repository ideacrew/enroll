module BenefitMarkets
  class BenefitSponsorCatalog
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :benefit_application, class_name: "::BenefitSponsors::BenefitApplications::BenefitApplication"

    field :effective_date,          type: Date 
    field :probation_period_kinds,  type: Array, default: []

    delegate :benefit_market_catalog, to: :benefit_application

    belongs_to  :service_area,
                class_name: "BenefitMarkets::Locations::ServiceArea"

    embeds_one  :sponsor_market_policy,
                class_name: "::BenefitMarkets::MarketPolicies::SponsorMarketPolicy"

    embeds_one  :member_market_policy,
                class_name: "::BenefitMarkets::MarketPolicies::MemberMarketPolicy"

    embeds_many :product_packages, as: :packagable,
                class_name: "::BenefitMarkets::Products::ProductPackage"


    def benefit_kinds
    end

    def product_market_kind
      :shop
    end

    def product_package_for(sponsored_benefit)
      product_packages.by_kind(sponsored_benefit.product_package_kind)
                      .by_product_kind(sponsored_benefit.product_kind)[0]
    end

    # TODO: check for late rate updates
    
    # def update_product_packages
    #   if is_product_package_update_available?
    #     product_packages.each do |product_package|
    #       product_package.update_products
    #     end
    #   end
    # end

    # def is_product_package_update_available?
    #   product_packages.any?{|product_package| benefit_market_catalog.is_product_package_updated?(product_package) }
    # end


    #FIX ME: Use configuration from benefit market
    def open_enrollment_start
      effective_date - 2.months
    end

    # FIX ME: Use configuration from benefit market
    def open_enrollment_end
      open_enrollment_month = effective_date.prev_month
      Date.new(open_enrollment_month.year, open_enrollment_month.month, 20)
    end
    
    def effective_period
      effective_date..effective_date.next_year.prev_day
    end

    def open_enrollment_period
      open_enrollment_start..open_enrollment_end
    end
    
    def product_active_year
      benefit_application.effective_period.begin.year
    end

    # product_option_choice: <metal level name>/<issuer name>
    def products_for(product_package, product_option_choice)
      return [] unless product_package
      product_package.products_for_plan_option_choice(product_option_choice)
    end
  end
end
