module ShopWidget
  class Carriers
    include Mongoid::Document
    store_in collection: "shopPolicies"

    field :tile , type: String
    # Field name should not start with int
    field :1plan_num, type: String
    field :1plan_pct, type: String
    field :1carrier_num, type: String
    field :1carrier_pct, type: String
    field :1metal_num, type: String
    field :1metal_pct, type: String
    
    default_scope ->{where(tile: "left_choice" )}
  end
end