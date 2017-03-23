module ShopWidget
  class ShopCensusMembers
    include Mongoid::Document
    store_in collection: "shopPolicies"

    field :tile , type: String
    field :enrolled_count, type: Integer
    field :enrolled_share, type: String
    field :enrolled_yoy, type: String
    field :not_enrolled_count, type: Integer
    field :not_enrolled_share, type: String
    field :not_enrolled_yoy, type: String

    default_scope ->{where(tile: "left_census" )}
  end
end