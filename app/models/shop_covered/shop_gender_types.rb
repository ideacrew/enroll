module ShopCovered
  class ShopGenderTypes
    include Mongoid::Document
    store_in collection: "shopCovered"

    field :tile , type: String
    field :male_count, type: Integer
    field :male_share, type: String
    field :male_yoy, type: String
    field :female_count, type: Integer
    field :female_share, type: String
    field :female_yoy, type: String
    
    default_scope ->{where(tile: "left_gender" )}
  end
end