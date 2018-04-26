module BenefitMarkets
  class Products::PremiumTable
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :product,
                class_name: "Products::Product"

    field :age, type: Integer
    field :start_on, type: Date
    field :end_on, type: Date
    field :cost, type: Float

    validates_presence_of :age, :start_on, :end_on, :cost
  end
end
