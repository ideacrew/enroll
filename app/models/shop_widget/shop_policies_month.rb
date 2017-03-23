module ShopWidget
  class ShopPoliciesMonth
    include Mongoid::Document
    store_in collection: "shopPolicies"

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
    
    field :policies_thirteen_one, type: Integer
    field :policies_thirteen_two, type: Integer
    field :policies_thirteen_three, type: Integer
    field :policies_thirteen_four, type: Integer

    field :policies_thirteen_five, type: Integer
    field :policies_thirteen_six, type: Integer
    field :policies_thirteen_seven, type: Integer
    field :policies_thirteen_eight, type: Integer

    field :policies_thirteen_nine, type: Integer
    field :policies_thirteen_ten, type: Integer
    field :policies_thirteen_eleven, type: Integer
    field :policies_thirteen_twelve, type: Integer

    field :policies_one_one, type: Integer
    field :policies_one_two, type: Integer
    field :policies_one_three, type: Integer
    field :policies_one_four, type: Integer

    field :policies_one_five, type: Integer
    field :policies_one_six, type: Integer
    field :policies_one_seven, type: Integer
    field :policies_one_eight, type: Integer

    field :policies_one_nine, type: Integer
    field :policies_one_ten, type: Integer
    field :policies_one_eleven, type: Integer
    field :policies_one_twelve, type: Integer

    default_scope ->{where(tile: "right_start_month" )}

  end
end