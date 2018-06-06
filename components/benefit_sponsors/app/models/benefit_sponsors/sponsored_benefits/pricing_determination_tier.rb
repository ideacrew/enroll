module BenefitSponsors
  module SponsoredBenefits
    class PricingDeterminationTier
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :pricing_determination, class_name: "::BenefitSponsors::SponsoredBenefits::PricingDetermination", inverse_of: :pricing_determination_tiers

      field :pricing_unit_id, type: BSON::ObjectId
      field :price, type: Float

      delegate :pricing_model, to: :pricing_determination

      def pricing_unit
        return @pricing_unit if defined? @pricing_unit
        @pricing_unit = pricing_model.find_by_pricing_unit(pricing_unit_id)
      end

      # FIXME: This exists only because it is needed by the legacy xml
      def contribution_percent
        pricing_determination.sponsored_benefit.sponsor_contribution
      end
    end
  end
end
