module IvlCovered
  class OverallGenderTypes
    include Mongoid::Document
    store_in collection: "ivlCovered"

    field :tile , type: String
    field :male_count, type: String
    field :male_share, type: String
    field :male_yoy, type: String
    field :female_count, type: String
    field :female_share, type: String
    field :female_yoy, type: String
    
    default_scope ->{where(tile: "left_gender" )}
  end
end