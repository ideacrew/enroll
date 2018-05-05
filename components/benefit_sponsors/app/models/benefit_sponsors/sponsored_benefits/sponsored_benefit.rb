module BenefitSponsors
  module SponsoredBenefits
    class SponsoredBenefit
      include Mongoid::Document
      include Mongoid::Timestamps

      FILTER_MAP =  { 
                      issuer_profiles: -> { products.issuer_profiles },
                      # metal_level_kinds: BenefitMarkets::Products::HealthProducts::HealthProduct::METAL_LEVEL_KINDS,
                      health_plan_kinds: BenefitMarkets::Products::HealthProducts::HealthProduct::HEALTH_PLAN_MAP.keys,
                    }


      field :hbx_id,      type: String
      field :kind,        type: Symbol
      field :plan_option_kind, type: String

      embeds_many :products, class_name: "::BenefitMarkets::Products::Product"
      embeds_one  :reference_product, class_name: "::BenefitMarkets::Products::Product"

      embeds_one  :sponsor_contribution, class_name: "::BenefitSponsors::SponsoredBenefits::SponsorContribution"
      embeds_many :pricing_determinations, class_name: "::BenefitSponsors::SponsoredBenefits::PricingDetermination"

      def latest_pricing_determination
        pricing_determinations.sort_by(&:created_at).last
      end
    end
  end
end