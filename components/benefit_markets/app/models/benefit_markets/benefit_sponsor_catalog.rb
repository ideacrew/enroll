module BenefitMarkets
  class BenefitSponsorCatalog
    include Mongoid::Document
    include Mongoid::Timestamps
    include Comparable

    embedded_in :benefit_application, class_name: "::BenefitSponsors::BenefitApplications::BenefitApplication"

    field :effective_date,          type: Date
    field :probation_period_kinds,  type: Array, default: []
    field :effective_period,        type: Range
    field :open_enrollment_period,  type: Range

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

    def comparable_attrs
      [:effective_date, :service_area, :sponsor_market_policy, :member_market_policy]
    end

    # Define Comparable operator
    # If instance attributes are the same, compare ProductPackages
    def <=>(other)
      if comparable_attrs.all? { |attr| eval(attr.to_s) == eval("other.#{attr.to_s}")  }
        if product_packages == other.product_packages
          0
        else
          product_packages <=> other.product_packages
        end
      else
        updated_on < other.updated_on ? -1 : 1
      end
    end

  end
end
