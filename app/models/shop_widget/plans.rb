module ShopWidget
  class Plans
    include Mongoid::Document
    store_in collection: "shopPolicies"

    field :tile , type: String
    field :plan_count, type: Integer
    field :plan_share, type: String
    field :plan_yoy, type: String
    
    field :carrier_count, type: Integer
    field :carrier_share, type: String
    field :carrier_yoy, type: String

    field :metal_count, type: Integer
    field :metal_share, type: String
    field :metal_yoy, type: String
    
    default_scope ->{where(tile: "left_choice" )}
  end
end