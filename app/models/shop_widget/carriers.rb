module ShopWidget
  class Carriers
    include Mongoid::Document
    store_in collection: "shp"

    field :tile , type: String
    # Field name should not start with int
    field :plan1_num, type: String
    field :plan1_pct, type: String
    field :carrier1_num, type: String
    field :carrier1_pct, type: String
    field :metal1_num, type: String
    field :metal1_pct, type: String
    
    default_scope ->{where(tile: "left_choice" )}
  end
end