module ShopCovered
  class ShopEnrollmentsMonth
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
    
    field :covered_thirteen_one, type: Integer
    field :covered_thirteen_two, type: Integer
    field :covered_thirteen_three, type: Integer
    field :covered_thirteen_four, type: Integer

    field :covered_thirteen_five, type: Integer
    field :covered_thirteen_six, type: Integer
    field :covered_thirteen_seven, type: Integer
    field :covered_thirteen_eight, type: Integer

    field :covered_thirteen_nine, type: Integer
    field :covered_thirteen_ten, type: Integer
    field :covered_thirteen_eleven, type: Integer
    field :covered_thirteen_twelve, type: Integer

    field :covered_one_one, type: Integer
    field :covered_one_two, type: Integer
    field :covered_one_three, type: Integer
    field :covered_one_four, type: Integer

    field :covered_one_five, type: Integer
    field :covered_one_six, type: Integer
    field :covered_one_seven, type: Integer
    field :covered_one_eight, type: Integer

    field :covered_one_nine, type: Integer
    field :covered_one_ten, type: Integer
    field :covered_one_eleven, type: Integer
    field :covered_one_twelve, type: Integer

    default_scope ->{where(tile: "right_start_month" )}

  end
end