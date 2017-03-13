module IvlPolicie
  class PolicyFamily
    include Mongoid::Document
    store_in collection: "ivlPolicies"

    field :tile , type: String
    field :one_count, type: Integer
    field :one_share, type: String
    field :one_yoy, type: String
    field :two_count, type: Integer
    field :two_share, type: String
    field :two_yoy, type: String
    field :three_count, type: Integer
    field :three_share, type: String
    field :three_yoy, type: String
    field :four_count, type: Integer
    field :four_share, type: String
    field :four_yoy, type: String
    field :five_count, type: Integer
    field :five_share, type: String
    field :five_yoy, type: String
    field :six_count, type: Integer
    field :six_share, type: String
    field :six_yoy, type: String
    field :seven_count, type: Integer
    field :seven_share, type: String
    field :seven_yoy, type: String


    default_scope ->{where(tile: "left_family_size" )}
  end
end