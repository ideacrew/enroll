module ShopCovered
  class ShopCarriersWidget
    include Mongoid::Document
    store_in collection: "shopCovered"

    field :tile , type: String
    field :carrier_first_name, type: String
    field :carrier_first_count, type: Integer
    field :carrier_first_share, type: String
    field :carrier_first_yoy, type: String
    field :carrier_second_name, type: String
    field :carrier_second_count, type: Integer
    field :carrier_second_share, type: String
    field :carrier_second_yoy, type: String

    field :carrier_third_name, type: String
    field :carrier_third_count, type: Integer
    field :carrier_third_share, type: String
    field :carrier_third_yoy, type: String
    field :carrier_fourth_name, type: String
    field :carrier_fourth_count, type: Integer
    field :carrier_fourth_share, type: String
    field :carrier_fourth_yoy, type: String


    default_scope ->{where(tile: "left_carrier" )}
  end
end