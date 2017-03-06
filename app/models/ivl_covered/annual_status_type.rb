module IvlCovered
  class AnnualStatusType
    include Mongoid::Document
    store_in collection: "ivlCovered"

    field :tile , type: String
    field :primary_count, type: String
    field :primary_share, type: String
    field :primary_yoy, type: String
    field :dependent_count, type: String
    field :dependent_share, type: String
    field :dependent_yoy, type: String

    default_scope ->{where(tile: "left_status" )}
  end
end