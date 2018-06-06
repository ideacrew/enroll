module BenefitSponsors
  module SponsoredBenefits
    class PricingDeterminationTier
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :pricing_determination, class_name: "::BenefitSponsors::SponsoredBenefits::PricingDetermination", inverse_of: :pricing_determination_tiers

      field :pricing_unit_id, type: BSON::ObjectId
      field :price, type: Float

      delegate :pricing_model, to: :pricing_determination
      delegate :sponsor_contribution, to: :pricing_determination

      def pricing_unit
        return @pricing_unit if defined? @pricing_unit
        @pricing_unit = pricing_model.find_by_pricing_unit(pricing_unit_id)
      end

      # FIXME: This is a legacy method that only exists for the XML.
      #        It tries to map contribution levels to pricing units,
      #        which is kind of inherently absurd.
      def sponsor_contribution_factor
        sponsor_contribution.match_contribution_level_for(pricing_unit).contribution_factor
      end
    end
  end
end
