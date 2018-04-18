module BenefitSponsors
  module SponsoredBenefits
    class PricingDetermination
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :sponsored_benefit, class_name: "::BenefitSponsors::SponsoredBenefits::SponsoredBenefit", inverse_of: :pricing_determinations
      embeds_many :pricing_determination_tiers, class_name: "::BenefitSponsors::SponsoredBenefits::PricingDeterminationTier"
    end
  end
end
