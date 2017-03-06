module IvlCovered
  class OverallAptc
    include Mongoid::Document
    store_in collection: "ivlCovered"

    field :tile , type: String
    field :tile, type: String
    field :yes_count, type: String
    field :yes_share, type: String
    field :yes_yoy, type: String
    field :no_count, type: String
    field :no_share, type: String
    field :no_yoy, type: String
    

    default_scope ->{where(tile: "left_aptc" )}
  end
end