module BenefitSponsors
  module SponsoredBenefits
    class SponsoredBenefit
      include Mongoid::Document
      include Mongoid::Timestamps

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