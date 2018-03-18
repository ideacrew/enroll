module SponsoredBenefits
  module RatingModels
    class RatingModel
      include Mongoid::Document
      include Mongoid::Timestamps

      field :benefit_market_kind, type: Symbol
      field :key,                 type: Symbol
      field :title,               type: String
      field :description,         type: String, default: ""

      embeds_many :rating_tiers,    class_name: "SponsoredBenefits::RatingModels::RatingTier"
      embeds_many :rating_factors,  class_name: "SponsoredBenefits::RatingModels::RatingFactor"

      # embeds_many :rating_areas,    class_name: "SponsoredBenefits::Locations::RatingArea"

      validates_presense_of :key, :title

      validates :benefit_market_kind,
        inclusion:  { in: SponsoredBenefits::BENEFIT_MARKET_KINDS, message: "%{value} is not a valid benefit market kind" },
        allow_nil:  false


    end
  end
end
