module ShopWidget
  class EmployerContributions
    include Mongoid::Document
    store_in collection: "shp"

    field :tile , type: String
    field :broker_yes_num, type: Integer
    field :pct_100, type: String
    field :carrier1_num, type: String
    field :carrier1_pct, type: Integer
    field :metal1_num, type: String
    field :metal1_pct, type: String

    default_scope ->{where(tile: "left_contrib" )}
  end
end