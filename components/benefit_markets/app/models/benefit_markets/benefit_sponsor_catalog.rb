module BenefitMarkets
  class BenefitSponsorCatalog
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :benefit_application, class_name: "::BenefitSponsors::BenefitApplications::BenefitApplication"

    field :effective_date,          type: Date 
    field :probation_period_kinds,  type: Array, default: []


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
      "shop"
    end
    
    def product_active_year
      benefit_application.effective_period.begin.year
    end
  end
end
