module ShopWidget
  class ShopTotalPolicies
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

    field :policies_one, type: Integer
    field :policies_two, type: Integer
    field :policies_three, type: Integer
    field :policies_four, type: Integer

    field :policies_five, type: Integer
    field :policies_six, type: Integer
    field :policies_seven, type: Integer
    field :policies_eight, type: Integer

    field :policies_nine, type: Integer
    field :policies_ten, type: Integer
    field :policies_eleven, type: Integer
    field :policies_twelve, type: Integer

    default_scope ->{where(tile: "right_census" )}

  end
end