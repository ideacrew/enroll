module BenefitMarkets
  class Products::PremiumTuple
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :premium_table, 
                class_name: "Products::PremiumTable"

    field :age,                 type: Integer
    field :cost,                type: Float

    validates_inclusion_of :age, :cost
  end
end
