module ShopCovered
  class ShopMetalWidget
    include Mongoid::Document
    store_in collection: "shopCovered"

    field :tile , type: String
    field :platinum_count, type: Integer
    field :platinum_share, type: String
    field :platinum_yoy, type: String
    field :gold_count, type: String
    field :gold_share, type: String
    field :gold_yoy, type: String
    field :silver_count, type: String
    field :silver_share, type: String
    field :silver_yoy, type: String
    field :bronze_count, type: String
    field :bronze_share, type: String
    field :bronze_yoy, type: String

    default_scope ->{where(tile: "left_metal" )}
  end
end