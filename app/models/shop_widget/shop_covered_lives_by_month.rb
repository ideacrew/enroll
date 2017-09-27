module ShopWidget
  class ShopCoveredLivesByMonth
    include Mongoid::Document
    store_in collection: "shp"

    field :tile , type: String

    field :jan_start, type: String
    field :feb_start, type: String
    field :mar_start, type: String
    field :apr_start, type: String

    field :may_start, type: String
    field :jun_start, type: String
    field :jul_start, type: String
    field :aug_start, type: String

    field :sep_start, type: String
    field :oct_start, type: String
    field :nov_start, type: String
    field :dec_start, type: String
    
    # field :projected_one, type: Integer
    # field :projected_two, type: Integer
    # field :projected_three, type: Integer
    # field :projected_four, type: Integer

    # field :projected_five, type: Integer
    # field :projected_six, type: Integer
    # field :projected_seven, type: Integer
    # field :projected_eight, type: Integer

    # field :projected_nine, type: Integer
    # field :projected_ten, type: Integer
    # field :projected_eleven, type: Integer
    # field :projected_twelve, type: Integer

    # field :actual_one, type: Integer
    # field :actual_two, type: Integer
    # field :actual_three, type: Integer
    # field :actual_four, type: Integer

    # field :actual_five, type: Integer
    # field :actual_six, type: Integer
    # field :actual_seven, type: Integer
    # field :actual_eight, type: Integer

    # field :actual_nine, type: Integer
    # field :actual_ten, type: Integer
    # field :actual_eleven, type: Integer
    # field :actual_twelve, type: Integer

    default_scope ->{where(tile: "right_graph" )}

  end
end