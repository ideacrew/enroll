module BenefitSponsors
  module SponsoredBenefits
    class PricingDeterminationTier
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :pricing_determination, class_name: "::BenefitSponsors::SponsoredBenefits::PricingDetermination", inverse_of: :pricing_determination_tiers

      field :pricing_unit_id, type: BSON::ObjectId
      field :price, type: Float
    end
  end
end
