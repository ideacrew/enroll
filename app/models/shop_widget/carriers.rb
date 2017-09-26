module ShopWidget
  class Carriers
    include Mongoid::Document
    store_in collection: "shp"

    field :tile , type: String
    field :plan1_num, type: Integer
    field :plan1_pct, type: String
    field :carrier1_num, type: Integer
    field :carrier1_pct, type: String
    field :metal1_num, type: Integer
    field :metal1_pct, type: String
    
    default_scope ->{where(tile: "left_choice" )}
  end
end