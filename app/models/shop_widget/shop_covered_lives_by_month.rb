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
    
    default_scope ->{where(tile: "right_graph" )}

  end
end