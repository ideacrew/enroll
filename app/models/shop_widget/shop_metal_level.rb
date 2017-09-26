module ShopWidget
  class ShopMetalLevel
    include Mongoid::Document
    store_in collection: "shp"

    field :tile , type: String
    field :plat_num, type: Integer
    field :plat_pct, type: String
    field :gold_num, type: Integer
    field :gold_pct, type: String
    field :silver_num, type: Integer
    field :silver_pct, type: String
    field :bronze_num, type: Integer
    field :bronze_pct, type: String

    default_scope ->{where(tile: "metal_lvl" )}
  end
end