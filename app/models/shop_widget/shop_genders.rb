module ShopWidget
  class ShopGenders
    include Mongoid::Document
    store_in collection: "shp"

    field :tile , type: String
    field :male_num, type: String
    field :male_pct, type: String
    field :female_num, type: String
    field :female_pct, type: String

    default_scope ->{where(tile: "gender" )}
  end
end