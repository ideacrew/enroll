module ShopWidget
  class ShopFamilyMembers
    include Mongoid::Document
    store_in collection: "shp"

    field :tile , type: String
    field :mem1_num, type: Integer
    field :mem1_pct, type: String
    field :mem2_num, type: Integer
    field :mem2_pct, type: String
    field :mem3_num, type: Integer
    field :mem3_pct, type: String
    field :mem4_num, type: Integer
    field :mem4_pct, type: String
    field :mem5_num, type: Integer
    field :mem5_pct, type: String
    field :mem6_num, type: Integer
    field :mem6_pct, type: String
    field :mem7_num, type: Integer
    field :mem7_pct, type: String

    default_scope ->{where(tile: "fam_size" )}
  end
end