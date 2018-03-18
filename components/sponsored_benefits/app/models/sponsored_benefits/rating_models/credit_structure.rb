module SponsoredBenefits
  module RatingModels
    class CreditStructure
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :rating_tier, class_name: "SponsoredBenefits::RatingModels::RatingTier"

    end
  end
end
