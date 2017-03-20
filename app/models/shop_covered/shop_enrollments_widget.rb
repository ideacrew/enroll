module ShopCovered
  class ShopEnrollmentsWidget
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
    
    field :census_one, type: Integer
    field :census_two, type: Integer
    field :census_three, type: Integer
    field :census_four, type: Integer

    field :census_five, type: Integer
    field :census_six, type: Integer
    field :census_seven, type: Integer
    field :census_eight, type: Integer

    field :census_nine, type: Integer
    field :census_ten, type: Integer
    field :census_eleven, type: Integer
    field :census_twelve, type: Integer

    field :covered_one, type: Integer
    field :covered_two, type: Integer
    field :covered_three, type: Integer
    field :covered_four, type: Integer

    field :covered_five, type: Integer
    field :covered_six, type: Integer
    field :covered_seven, type: Integer
    field :covered_eight, type: Integer

    field :covered_nine, type: Integer
    field :covered_ten, type: Integer
    field :covered_eleven, type: Integer
    field :covered_twelve, type: Integer

    default_scope ->{where(tile: "right_census" )}

  end
end