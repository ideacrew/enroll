module ShopWidget
  class ShopCensusEmployees
    include Mongoid::Document
    store_in collection: "shp"

    field :tile , type: String
    field :num_100, type: Integer
    field :pct_100, type: String
    field :carrier1_num, type: Integer
    field :carrier1_pct, type: String
    field :metal1_num, type: Integer
    field :metal1_pct, type: String

    default_scope ->{where(tile: "left_census" )}
  end
end