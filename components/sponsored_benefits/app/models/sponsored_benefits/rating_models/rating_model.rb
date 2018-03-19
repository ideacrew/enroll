module SponsoredBenefits
  module RatingModels
    class RatingModel
      include Mongoid::Document
      include Mongoid::Timestamps

      field :hbx_id,                type: String
      field :title,                 type: String
      field :description,           type: String, default: ""

      field :credit_structure_kind, type: Symbol

      belongs_to  :benefit_catalog,       class_name: "SponsoredBenefits::BenefitCatalogs::BenefitCatalog"
      embeds_many :rating_tiers,          class_name: "SponsoredBenefits::RatingModels::RatingTier"
      embeds_many :rating_factors,        class_name: "SponsoredBenefits::RatingModels::RatingFactor"

      # embeds_many :rating_areas,    class_name: "SponsoredBenefits::Locations::RatingArea"

      validates :credit_structure_kind,
        inclusion:  { in: CreditStructure::KINDS, message: "%{value} is not a valid credit structure kind" },
        allow_nil:  false


      validates_presense_of :hbx_id, :title


    end
  end
end
