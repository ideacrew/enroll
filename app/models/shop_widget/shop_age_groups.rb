module ShopWidget
  class ShopAgeGroups
    include Mongoid::Document
    store_in collection: "shp"

    field :tile , type: String
    field :age1_num, type: String
    field :age1_pct, type: String
    field :age17_num, type: String
    field :age17_pct, type: String

    field :age25_num, type: String
    field :age25_pct, type: String
    field :age34_num, type: String
    field :age34_pct, type: String

    field :age44_num, type: String
    field :age44_pct, type: String
    field :age54_num, type: String
    field :age54_pct, type: String
    
    field :age64_num, type: String
    field :age64_pct, type: String
    field :age65_num, type: String
    field :age65_pct, type: String
    
    default_scope ->{where(tile: "age_grp" )}
  end
end