module ShopWidget
  class ShopBenefits
    include Mongoid::Document
    store_in collection: "shp"

    field :tile , type: String
    field :date_hire_num, type: Integer
    field :date_hire_pct, type: String
    field :first_mth_num, type: Integer
    field :first_mth_pct, type: String
    field :day30_num, type: Integer
    field :day30_pct, type: String
    field :day60_num, type: Integer
    field :day60_pct, type: String
    
    default_scope ->{where(tile: "left_hire" )}
  end
end