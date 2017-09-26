module ShopWidget
  class Brokers
    include Mongoid::Document
    store_in collection: "shp"

    field :tile , type: String
    field :num_100, type: String
    field :broker_yes_pct, type: String
    field :broker_no_num, type: String
    field :broker_no_pct, type: String

    default_scope ->{where(tile: "left_broker" )}
  end
end