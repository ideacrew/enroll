module BenefitSponsors
  module SponsoredBenefits
    class HealthSponsoredBenefit < SponsoredBenefit


      FILTER_MAP =  { 
                      issuer_profiles: -> { products.issuer_profiles },
                      # metal_level_kinds: BenefitMarkets::Products::HealthProducts::HealthProduct::METAL_LEVEL_KINDS,
                      health_plan_kinds: BenefitMarkets::Products::HealthProducts::HealthProduct::HEALTH_PLAN_MAP.keys,
                    }

      embeds_one  :reference_product, 
                  class_name: "::BenefitMarkets::Products::HealthProducts::HealthProduct"
      embeds_many :products, 
                  class_name: "::BenefitMarkets::Products::HealthProducts::HealthProduct"
    end
  end
end
