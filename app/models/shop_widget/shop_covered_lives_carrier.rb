module ShopWidget
  class ShopCoveredLivesCarrier
    include Mongoid::Document
    store_in collection: "shp"

    field :tile , type: String
    field :aetna_num, type: Integer
    field :aetna_pct, type: String
    field :cf_num, type: Integer
    field :cf_pct, type: String
    field :kp_num, type: Integer
    field :kp_pct, type: String
    field :united_num, type: Integer
    field :united_pct, type: String

    default_scope ->{where(tile: "carrier" )}
  end
end