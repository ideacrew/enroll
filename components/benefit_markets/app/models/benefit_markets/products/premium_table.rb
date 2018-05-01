module BenefitMarkets
  class Products::PremiumTable
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :product,
                class_name: "Products::Product"

    field :effective_period,  type: Range

    belongs_to  :rating_area,
                class_name: "BenefitMarkets::Locations::RatingArea"

    embeds_many :premium_tuples,
                class_name: "Products::PremiumTuple"

    validates_presence_of :effective_period, :rating_area

  end
end
