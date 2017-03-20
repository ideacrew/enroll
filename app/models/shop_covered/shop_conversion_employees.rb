module ShopCovered
  class ShopConversionEmployees
    include Mongoid::Document
    store_in collection: "shopCovered"

    field :tile , type: String
    field :month_one, type: String
    field :month_two, type: String
    field :month_three, type: String
    field :month_four, type: String

    field :month_five, type: String
    field :month_six, type: String
    field :month_seven, type: String
    field :month_eight, type: String

    field :month_nine, type: String
    field :month_ten, type: String
    field :month_eleven, type: String
    field :month_twelve, type: String
    
    field :projected_one, type: Integer
    field :projected_two, type: Integer
    field :projected_three, type: Integer
    field :projected_four, type: Integer

    field :projected_five, type: Integer
    field :projected_six, type: Integer
    field :projected_seven, type: Integer
    field :projected_eight, type: Integer

    field :projected_nine, type: Integer
    field :projected_ten, type: Integer
    field :projected_eleven, type: Integer
    field :projected_twelve, type: Integer

    field :actual_one, type: Integer
    field :actual_two, type: Integer
    field :actual_three, type: Integer
    field :actual_four, type: Integer

    field :actual_five, type: Integer
    field :actual_six, type: Integer
    field :actual_seven, type: Integer
    field :actual_eight, type: Integer

    field :actual_nine, type: Integer
    field :actual_ten, type: Integer
    field :actual_eleven, type: Integer
    field :actual_twelve, type: Integer

    default_scope ->{where(tile: "right_conversion" )}

  end
end