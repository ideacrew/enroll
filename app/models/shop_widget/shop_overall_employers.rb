module ShopWidget
  class ShopOverallEmployers
    include Mongoid::Document
    store_in collection: "shp"

    field :tile , type: String
    field :active_empler, type: Boolean
    field :covered_empl, type: Integer
    field :percent_empl, type: String
    field :total_covered, type: String

    default_scope ->{where(tile: "top" )}
  end
end