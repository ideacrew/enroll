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

      embedded_in :benefit_package, class_name: "BenefitSponsors::BenefitPackages::BenefitPackage"

      field :hbx_id,      type: String
      field :kind,        type: Symbol
      field :plan_option_kind, type: String

      embeds_many :products, class_name: "::BenefitMarkets::Products::Product"
      embeds_one  :reference_product, class_name: "::BenefitMarkets::Products::Product"

      embeds_one  :sponsor_contribution, class_name: "::BenefitSponsors::SponsoredBenefits::SponsorContribution"
      embeds_many :pricing_determinations, class_name: "::BenefitSponsors::SponsoredBenefits::PricingDetermination"

      delegate :benefit_sponsor_catalog, to: :benefit_package

      def latest_pricing_determination
        pricing_determinations.sort_by(&:created_at).last
      end

      def carrier_for_elected_plan=(issuer_name)
        return if issuer_name.blank?
        self.products = benefit_sponsor_catalog.products_for(plan_option_kind, issuer_name)
      end

      def metal_level_for_elected_plan=(metal_level)
        return if metal_level.blank?
        self.products = benefit_sponsor_catalog.products_for(plan_option_kind, metal_level)
      end

      def reference_plan_id=(product_id)
        self.reference_product = products.where(id: product_id).first
      end

      def sponsor_contributions=(sponsor_contribution_attrs)
        build_sponsor_contribution(sponsor_contribution_attrs)
      end
    end
  end
end