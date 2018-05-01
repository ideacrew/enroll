module BenefitMarkets
  class BenefitSponsorCatalog
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :benefit_application

    field :effective_date,    type: Date 
    field :probation_period_kinds, type: Array, default: []
    field :service_area_id

    embeds_one  :sponsor_market_policy,  
                class_name: "::BenefitMarkets::MarketPolicies::SponsorMarketPolicy"
    embeds_one  :member_market_policy,
                class_name: "::BenefitMarkets::MarketPolicies::MemberMarketPolicy"
    embeds_many :product_packages,
                class_name: "::BenefitMarkets::Products::ProductPackage"
  end
end
