module ShopWidget
  class ShopEmployees
    include Mongoid::Document
    store_in collection: "shp"

    field :tile , type: String
    field :num_1_9, type: String
    field :pct_1_9, type: String
    field :num_10_24, type: String
    field :pct_10_24, type: String
    field :num_25_50, type: String
    field :pct_25_50, type: String
    field :num_51_100, type: String
    field :pct_51_100, type: String
    field :num_100, type: String
    field :pct_100, type: String

    default_scope ->{where(tile: "left_enrollment" )}
  end
end