module IvlPolicie
  class PolicyTotalMetalTypes
    include Mongoid::Document
    store_in collection: "ivlPolicies"

    field :tile , type: String
    field :platinum_count, type: Integer
    field :platinum_share, type: String
    field :platinum_yoy, type: String
    field :gold_count, type: Integer
    field :gold_share, type: String
    field :gold_yoy, type: String
    field :silver_count, type: Integer
    field :silver_share, type: String
    field :silver_yoy, type: String
    field :bronze_count, type: Integer
    field :bronze_share, type: String
    field :bronze_yoy, type: String
    field :catastrophic_count, type: Integer
    field :catastrophic_share, type: String
    field :catastrophic_yoy, type: String

    default_scope ->{where(tile: "left_metal" )}
  end
end